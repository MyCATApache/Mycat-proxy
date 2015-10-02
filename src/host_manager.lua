--------------------------------------
--@desc:管理主机的添加和删除
--@author:coder_czp
--@date:2015/9/19
--------------------------------------

local Util  = require("util")
local Proxy = require("proxy")
local DB    = require("ljsqlite3")

local sql_host  = "CREATE TABLE IF NOT EXISTS host_tbl(host varchar,port varchar,weight varchar,primary key(host,port))"
local sql_glob  = "CREATE TABLE IF NOT EXISTS glb_tbl (lb_type varchar,port varchar, primary key(port))"
local sql_dft   = "DELETE FROM glb_tbl ;INSERT INTO glb_tbl (lb_type,port) VALUES('round','1025')"
local sql_check = "SELECT name FROM sqlite_master where type='table' and name='host_tbl'"
local btn_fmt   = "<button  onclick=delHost('%s','%s')>安全下线 </button>"
local tbl_fmt   = "<tr><td>%s</td><td>%s</td><td>%s</td><td>online</td><td>%s</td></tr>"
local sql_all   = table.concat({sql_host,sql_glob,sql_dft},";")
local view_tpl  = "/view/host_mgr.html"
local db_path   = "data/host.db"
local has_init  = false
local proxy_run = false

--获取数据库连接
local function getDbConn()
  local conn  = DB.open(db_path,"rwc")
  if not has_init then
    local rows,count = conn:exec(sql_check)
    if count <1 then conn:exec(sql_all) end
    has_init = true
  end
  return conn
end

--更新prxoy的配置,不会关闭连接
local function reload_proxy(db_conn)

  --  local cpu_num     = tonumber(os.getenv("NUMBER_OF_PROCESSORS"))
  local rips      = {}
  local sql       = "SELECT * FROM host_tbl"
  local stmt      = db_conn:prepare(sql)
  local tmp       = ""
  local row       = {}
  local found     = nil
  while stmt:step(row) do
    local backend_ser = {ip=row[1],port=row[2],weight=row[3]}
    table.insert(rips,backend_ser)
    found = true
  end

  if found == nil then
    return print("server list is empty")
  end
  -- 查询代理端口和策略
  local rows,count  = db_conn:exec("SELECT * FROM glb_tbl")
  local rmodel      = rows[1][1]
  local rport       = rows[2][1]

  local config = {model =rmodel,ips = rips,port= rport}
  if not proxy_run then
    proxy_run = true
    Proxy.start(config)
    print("start_proxy server ",rport)
  else
    Proxy.reload(config)
    print("reload_proxy server ",rport)
  end

end

--查询主机信息
local function _query()

  local row       = {}
  local html      = {}
  local conn      = getDbConn()
  local sql_host  = "SELECT * FROM host_tbl"
  local sql_glob  = "SELECT * FROM glb_tbl"
  local db_stmt   = conn:prepare(sql_host)
  local rowset,n  = conn:exec(sql_glob)

  local host,port,tmp
  while db_stmt:step(row) do
    host = row[1]
    port = row[2]
    tmp  = string.format(btn_fmt,host,port)
    tmp  = string.format(tbl_fmt,row[1],row[2],row[3],tmp)
    table.insert(html,tmp)
  end

  --如果有记录,就启动代理
  if host then reload_proxy(conn) end
  local glob_port      = rowset[2][1]
  local route_type     = rowset[1][1]
  local ip_hash_select = ""
  local round_select   = ""

  --web选中对应的单选框
  if route_type == "ip_hash" then
    ip_hash_select = "checked"
  else
    round_select   = "checked"
  end

  conn:close()
  return {view=view_tpl,res={table.concat(html),ip_hash_select,round_select,glob_port}}
end

--添加主机
local function _add(tbl)
  if tbl == nil or tbl.port == nil or tbl.host == nil or tbl.weight == nil then
    return Util.json({code=503,info="host port weight is required"}),true
  end

  --如果重复添加则替换
  local fmt_str = "REPLACE INTO host_tbl VALUES('%s','%s','%s')"
  local add_sql = string.format(fmt_str,tbl.host,tbl.port,tbl.weight)
  local conn    = getDbConn()
  conn:exec(add_sql);
  reload_proxy(conn)
  conn:close()
  return Util.json({code=200,info="add success"}),true
end

--添加Glob参数
local function _addGlob(tbl)
  if tbl == nil or tbl.type == nil or tbl.port == nil  then
    return Util.json({code=503,info="reoute type ,port is required"}),true
  end
  --先删除再插入
  local fmt_str = "DELETE FROM glb_tbl;INSERT INTO glb_tbl VALUES('%s','%s')"
  local add_sql = string.format(fmt_str,tbl.type,tbl.port)
  local conn    = getDbConn()
  conn:exec(add_sql)
  reload_proxy(conn)
  conn:close()
  return Util.json({code=200,info="add success"}),true
end

--删除主机
local function _delHost(tbl)
  local fmt_str = "DELETE FROM host_tbl WHERE host='%s' and port='%s'"
  local del_sql = string.format(fmt_str,tbl.host,tbl.port)
  local conn    = getDbConn()
  conn:exec(del_sql)
  reload_proxy(conn)
  conn:close()
  return Util.json({code=200,info="del success"}),true
end

--停止服务
local function _stop()
  return Util.json({code=200,info="stop success"}),true
end

local _M = {
  delHost = _delHost,
  addGlob = _addGlob,
  query = _query,
  stop = _stop,
  add = _add
}

return _M
