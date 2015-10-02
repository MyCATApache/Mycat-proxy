--------------------------------------
--@desc:web入口
--@author:coder_czp
--@date:2015/9/19
--------------------------------------
--
package.path = package.path  .. ";src/?.lua"

--只能在这个入口文件访问deps模块,所以将需要的模块导出到_G

_G['fs']       = require('fs')
local Response = require('http').ServerResponse
local disp     = require('dispatch')
local mimes    = require('mime')
local http     = require('http')
local url      = require('url')
local fs       = _G['fs']

local web_config = {
  root = "web",
  port = 8080
}

local function getType(path)
  return mimes[path:lower():match("[^.]*$")] or mimes.default
end

-- handle not found
function Response:notFound(reason)
  self:writeHead(404, {
    ["Content-Type"] = "text/plain",
    ["Content-Length"] = #reason
  })
  self:write(reason)
end

-- handle error
function Response:error(reason)
  self:writeHead(500, {
    ["Content-Type"] = "text/plain",
    ["Content-Length"] = #reason
  })
  self:write(reason)
end

--创建文件夹
local function create_folder(path)
  local res = fs.existsSync(path)
  if not res then fs.mkdirSync(path) end
end

local function start_http()
  http.createServer(function(req, res)

      if req.url =="/" then req.url = "/index.html" end
      req.uri = url.parse(req.url,true)

      --动态页面
      if req.url:match("/admin/*") then
        p('path',req.url)
        return disp.dipatch(res,req.url,req.uri.query,web_config.root)
      end

      --静态页面
      local root = web_config.root
      local path = root .. req.uri.pathname
      --p('path',path)
      fs.stat(path, function (err, stat)
        if err then
          if err.code == "ENOENT" then
            return res:notFound(err.message .. "\n")
          end
          return res:error((err.message or tostring(err)) .. "\n")
        end
        --p(stat) --dump start
        if stat.type ~= 'file'    then
          return res:notFound("Requested url is not a file\n")
        end

        res:writeHead(200, {
          ["Content-Type"] = getType(path),
          ["Content-Length"] = stat.size
        })

        fs.createReadStream(path):pipe(res)

      end)

  end):listen(web_config.port)
end

local function main(param)
  local port = tonumber(param[2])
  if port == nil then
    print(string.format("Usage:%s port",param[1]))
    os.exit(1)
  else
    web_config.port = port
    create_folder("data")
    start_http()
    print("server runing at:",port)
  end
end

main(arg or args)
