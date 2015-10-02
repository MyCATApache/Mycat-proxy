--------------------------------------
--@desc:工具类
--@author:coder_czp
--@date:2015/9/19
--------------------------------------

local xsys = require("xsys")

local function _json(tbl)
  if tbl == nil then return nil end
  local res_tbl = {}
  for k,v in pairs(tbl) do
    table.insert(res_tbl,string.format('"%s":"%s"',k,v))
  end
  local json = {"{",table.concat(res_tbl,","),"}"}
  return table.concat(json)
end

--解码
local function _decodeURI(s)
  s = string.gsub(s, '%%(%x%x)',function(h)
    return string.char(tonumber(h, 16)) end)
  return s
end

--加码
local function _encodeURI(s)
  s = string.gsub(s, "([^%w%.%- ])",function(c)
    return string.format("%%%02X", string.byte(c)) end)
  return string.gsub(s, " ", "+")
end

--获取文件名
local function _getFileName(str)
  local idx = str:match(".+()%.%w+$")
  if(idx) then return str:sub(1, idx-1)
  else return str end
end

--获取扩展名
local function _getExtension(str)
  return str:match("[^.]*$")
end


local _M = {
  split = xsys.string.split,
  getExtension =_getExtension,
  getFileName = _getFileName,
  encodeURI  =_encodeURI,
  decodeURI =_decodeURI,
  json = _json
}

return _M
