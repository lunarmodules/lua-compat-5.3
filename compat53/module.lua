local _G, _VERSION, debug, error, require, setfenv, setmetatable =
      _G, _VERSION, debug, error, require, setfenv, setmetatable
local lua_version = _VERSION:sub(-3)
local M = require("compat53.base")

local function findmain()
   local i = 3
   local info = debug.getinfo(i, "fS")
   while info do
      if info.what == "main" then
         return info.func
      end
      i = i + 1
      info = debug.getinfo(i, "fS")
   end
end

local main = findmain()
if not main then
   error("must require 'compat53.module' from Lua")
end
local env = setmetatable({}, {
   __index = M,
   __newindex = _G,
})
if lua_version == "5.1" then
   setfenv(main, env)
elseif lua_version == "5.2" or lua_version == "5.3" then
   debug.setupvalue(main, 1, env)
else
   error("unsupported Lua version")
end

-- return false to force reevaluation on next require
return false

-- vi: set expandtab softtabstop=3 shiftwidth=3 :
