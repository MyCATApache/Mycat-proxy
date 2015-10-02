--------------------------------------
--@desc:请求分发类
--@author:coder_czp
--@date:2015/9/19
--------------------------------------

local Route   = require("route_manager")
local Host    = require("host_manager")
local Util    = require("util")

local foot,head
local mvc_map = {}
mvc_map["/admin/lb/delHost"] = Host.delHost
mvc_map["/admin/lb/addGlob"] = Host.addGlob
mvc_map["/admin/lb/delHost"] = Host.delHost
mvc_map["/admin/lbquery"] = Host.query
mvc_map["/admin/lb/stop"] = Host.stop
mvc_map["/admin/lbadd"] = Host.add
mvc_map["/admin/route"] = Route.query

--根据请求调用处理逻辑
local function call_logic(url,args)
  local result = nil
  local isjson = false

  for k,handler in pairs(mvc_map) do
    if string.find(url,k) then
      result,isjson = handler(args)
      return isjson,result
    end
  end
  return isjson,{view="50x.html",res={}}
end

local function readAll(file_path)
  local context ={}
  local file =  io.open(file_path,"r")
  for line in file:lines() do
    table.insert(context,line)
  end
  file:close()
  return table.concat(context)
end

--读取共用的头尾
local function readFootAndHead(web_dir)
  if foot then return head,foot end
  head =  readAll(web_dir.."/view/head.html")
  foot = readAll(web_dir.."/view/foot.html")
  return head,foot
end


--处理请求
local function _dipatch(res,url,args,web_dir)

  local isjson,result = call_logic(url,args)

  if isjson then
    res:writeHead(200, {
      ["Content-Type"] = "application/json"
    })
    res:finish(result)
    return 200
  end

  readFootAndHead(web_dir)

  --替换模板中的占位符
  local place_holder = nil
  local tpl_html     = readAll(web_dir ..result.view)
  for k,v in pairs(result.res) do
    place_holder = string.format("{#%s}",k)
    tpl_html     = string.gsub(tpl_html,place_holder,v)
  end

  res:writeHead(200, {
    ["Content-Type"] = "text/html"
  })
  res:finish(table.concat({head,tpl_html,foot}))

  return 200
end

local _M = {dipatch = _dipatch}

return _M
