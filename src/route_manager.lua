--------------------------------------
--@desc:路由信息管理类
--@author:coder_czp
--@date:2015/9/19
--------------------------------------

local Proxy = require("proxy")
local Util = require("util")
local fs   = _G['fs']

local page_size     = 20
local each_line_len = 104
local log           = "data/proxy.log"
local view          = "/view/route_mgr.html"
local fmt           = "<tr><td>%s<td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>"

--分页读取
local function readPage(fd,page,page_size,each_line_size,all)
  local endOfFile = all * each_line_size
  local readSize  = page_size*each_line_size
  local offset    = (page-1) *page_size * each_line_size
  if offset > endOfFile then offset = endOfFile end
  return fs.readSync(fd, readSize, offset)
end

--生成分页html 1|2|N
local function generate_page_html(cur_page,count)
  local active_fmt = "<li class='active'><a href='%s'>%s</a></li>"
  local fmt        = "<li><a href='%s'>%s</a></li>"
  local pages      = math.ceil(count / page_size)
  local alink      = nil
  local page_html  = {}

  --占时只显示前10页
  if pages > 10 then pages = 10 end
  for i=1,pages do
    alink = string.format("/admin/route?p=%s",i)
    if i == cur_page then
      table.insert(page_html,string.format(active_fmt,alink,i))
    else
      table.insert(page_html,string.format(fmt,alink,i))
    end
  end
  return table.concat(page_html)

end

--生成每个服务请求次数的html
local function generate_classify_html()
  local tbl = Proxy.statistics().each_ser_count
  if tbl == nil then return "no request info" end
  local result = {}
  for k,v in pairs(tbl) do
    table.insert(result,string.format("[%s=%s]",k,v))
  end
  return table.concat(result)
end

--查询路由信息
local function _query_route_info(query_args)

  local cur_page = tonumber(query_args.p) or 1
  local count    = Proxy.statistics().request_cout
 
  local tbl,str
  local tmp  = {}
  local fd = fs.openSync(log,"r")

  if not fd then return {view=view,res={"",0,0,"",""}} end

  local lines = readPage(fd,cur_page,page_size,each_line_len,count)
  local splits = Util.split(lines,"\n")
  for k,line in pairs(splits) do
    if line~= "" then
      tbl   = Util.split(line," ")
      str   = string.format(fmt,k,tbl[1],tbl[2],tbl[3],tbl[5],tbl[7])
      table.insert(tmp,str)
    end
  end
  fs.close(fd)

  --分服务统计
  local classify_html = generate_classify_html()
  --分页html
  local page_html     = generate_page_html(cur_page,count)

  return {view=view,res={table.concat(tmp),count,page_size,page_html,classify_html}}

end

local _M = {
  query = _query_route_info
}

return _M
