#!/usr/bin/env lua

local F, ___
do
  local type, unpack = type, table.unpack or unpack
  function F(...)
    local args, n = { ... }, select('#', ...)
    for i = 1, n do
      local t = type(args[i])
      if t ~= "string" and t ~= "number" and t ~= "boolean" then
        args[i] = t
      end
    end
    return unpack(args, 1, n)
  end
  local sep = ("="):rep(70)
  function ___()
    print(sep)
  end
end

print( "testing Lua API ..." )
package.path = "../?.lua;"..package.path
require("compat53")

___''
do
  local t = setmetatable( {}, { __index = { 1, false, "three" } } )
  for i,v in ipairs(t) do
    print("ipairs", i, v)
  end
end


___''
print("math.maxinteger", math.maxinteger+1 > math.maxinteger)
print("math.mininteger", math.mininteger-1 < math.mininteger)


___''
print("math.tointeger", math.tointeger(0))
print("math.tointeger", math.tointeger(math.pi))
print("math.tointeger", math.tointeger("hello"))
print("math.tointeger", math.tointeger(math.maxinteger+2.0))
print("math.tointeger", math.tointeger(math.mininteger*2.0))


___''
print("math.type", math.type(0))
print("math.type", math.type(math.pi))
print("math.type", math.type("hello"))


___''
print("math.ult", math.ult(1, 2), math.ult(2, 1))
print("math.ult", math.ult(-1, 2), math.ult(2, -1))
print("math.ult", math.ult(-1, -2), math.ult(-2, -1))
print("math.ult", pcall(math.ult, "x", 2))
print("math.ult", pcall(math.ult, 1, 2.1))
___''



print("testing C API ...")
local mod = require("testmod")
___''
print(mod.isinteger(1))
print(mod.isinteger(0))
print(mod.isinteger(1234567))
print(mod.isinteger(12.3))
print(mod.isinteger(math.huge))
print(mod.isinteger(math.sqrt(-1)))


___''
print(mod.rotate(1, 1, 2, 3, 4, 5, 6))
print(mod.rotate(-1, 1, 2, 3, 4, 5, 6))
print(mod.rotate(4, 1, 2, 3, 4, 5, 6))
print(mod.rotate(-4, 1, 2, 3, 4, 5, 6))


___''
print(mod.strtonum("+123"))
print(mod.strtonum(" 123 "))
print(mod.strtonum("-1.23"))
print(mod.strtonum(" 123 abc"))
print(mod.strtonum("jkl"))


___''
local a, b, c = mod.requiref()
print( type(a), type(b), type(c),
       a.boolean, b.boolean, c.boolean,
       type(requiref1), type(requiref2), type(requiref3))

___''
local proxy, backend = {}, {}
setmetatable(proxy, { __index = backend, __newindex = backend })
print(rawget(proxy, 1), rawget(backend, 1))
print(mod.getseti(proxy, 1))
print(rawget(proxy, 1), rawget(backend, 1))
print(mod.getseti(proxy, 1))
print(rawget(proxy, 1), rawget(backend, 1))

-- tests for Lua 5.1
___''
print(mod.tonumber(12))
print(mod.tonumber("12"))
print(mod.tonumber("0"))
print(mod.tonumber(false))
print(mod.tonumber("error"))

___''
print(mod.tointeger(12))
print(mod.tointeger("12"))
print(mod.tointeger("0"))
print( "aaa" )
print(mod.tointeger(math.pi))
print( "bbb" )
print(mod.tointeger(false))
print(mod.tointeger("error"))

___''
print(mod.len("123"))
print(mod.len({ 1, 2, 3}))
print(pcall(mod.len, true))
local ud, meta = mod.newproxy()
meta.__len = function() return 5 end
print(mod.len(ud))
meta.__len = function() return true end
print(pcall(mod.len, ud))

___''
print(mod.copy(true, "string", {}, 1))

___''
print(mod.rawxetp())
print(mod.rawxetp("I'm back"))

___''
print(F(mod.globals()), mod.globals() == _G)

___''
local t = {}
print(F(mod.subtable(t)))
local x, msg = mod.subtable(t)
print(F(x, msg, x == t.xxx))

___''
print(F(mod.udata()))
print(mod.udata("nosuchtype"))

___''
print(F(mod.uservalue()))

___''
print(mod.getupvalues())

___''
print(mod.absindex("hi", true))

___''
print(mod.tolstring("string"))
local t = setmetatable({}, {
  __tostring = function(v) return "mytable" end
})
print(mod.tolstring(t))
local t = setmetatable({}, {
  __tostring = function(v) return nil end
})
print(pcall(mod.tolstring, t))
___''

