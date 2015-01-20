#!/usr/bin/env lua

local F, tproxy, ___
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
  function tproxy(t)
    return setmetatable({}, {
      __index = t,
      __newindex = t,
      __len = function() return #t end,
    }), t
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
do
  local p, t = tproxy{ "a", "b", "c" }
  print("table.concat", table.concat(p))
  print("table.concat", table.concat(p, ",", 2))
  print("table.concat", table.concat(p, ".", 1, 2))
  print("table.concat", table.concat(t))
  print("table.concat", table.concat(t, ",", 2))
  print("table.concat", table.concat(t, ".", 1, 2))
end


___''
do
  local p, t = tproxy{ "a", "b", "c" }
  table.insert(p, "d")
  print("table.insert", next(p), t[4])
  table.insert(p, 1, "z")
  print("table.insert", next(p),  t[1], t[2])
  table.insert(p, 2, "y")
  print("table.insert", next(p), t[1], t[2], p[3])
  t = { "a", "b", "c" }
  table.insert(t, "d")
  print("table.insert", t[1], t[2], t[3], t[4])
  table.insert(t, 1, "z")
  print("table.insert", t[1], t[2], t[3], t[4], t[5])
  table.insert(t, 2, "y")
  print("table.insert", t[1], t[2], t[3], t[4], t[5])
end


___''
do
  local ps, s = tproxy{ "a", "b", "c", "d" }
  local pd, d = tproxy{ "A", "B", "C", "D" }
  table.move(ps, 1, 4, 1, pd)
  print("table.move", next(pd), d[1], d[2], d[3], d[4])
  pd, d = tproxy{ "A", "B", "C", "D" }
  table.move(ps, 2, 4, 1, pd)
  print("table.move", next(pd), d[1], d[2], d[3], d[4])
  pd, d = tproxy{ "A", "B", "C", "D" }
  table.move(ps, 2, 3, 4, pd)
  print("table.move", next(pd), d[1], d[2], d[3], d[4], d[5])
  table.move(ps, 2, 4, 1)
  print("table.move", next(ps), s[1], s[2], s[3], s[4])
  ps, s = tproxy{ "a", "b", "c", "d" }
  table.move(ps, 2, 3, 4)
  print("table.move", next(ps), s[1], s[2], s[3], s[4], s[5])
  s = { "a", "b", "c", "d" }
  d = { "A", "B", "C", "D" }
  table.move(s, 1, 4, 1, d)
  print("table.move", d[1], d[2], d[3], d[4])
  d = { "A", "B", "C", "D" }
  table.move(s, 2, 4, 1, d)
  print("table.move", d[1], d[2], d[3], d[4])
  d = { "A", "B", "C", "D" }
  table.move(s, 2, 3, 4, d)
  print("table.move", d[1], d[2], d[3], d[4], d[5])
  table.move(s, 2, 4, 1)
  print("table.move", s[1], s[2], s[3], s[4])
  s = { "a", "b", "c", "d" }
  table.move(s, 2, 3, 4)
  print("table.move", s[1], s[2], s[3], s[4], s[5])
end


___''
do
  local p, t = tproxy{ "a", "b", "c", "d", "e" }
  print("table.remove", table.remove(p))
  print("table.remove", next(p), t[1], t[2], t[3], t[4], t[5])
  print("table.remove", table.remove(p, 1))
  print("table.remove", next(p), t[1], t[2], t[3], t[4])
  print("table.remove", table.remove(p, 2))
  print("table.remove", next(p), t[1], t[2], t[3])
  print("table.remove", table.remove(p, 3))
  print("table.remove", next(p), t[1], t[2], t[3])
  p, t = tproxy{}
  print("table.remove", table.remove(p))
  print("table.remove", next(p), next(t))
  t = { "a", "b", "c", "d", "e" }
  print("table.remove", table.remove(t))
  print("table.remove", t[1], t[2], t[3], t[4], t[5])
  print("table.remove", table.remove(t, 1))
  print("table.remove", t[1], t[2], t[3], t[4])
  print("table.remove", table.remove(t, 2))
  print("table.remove", t[1], t[2], t[3])
  print("table.remove", table.remove(t, 3))
  print("table.remove", t[1], t[2], t[3])
  t = {}
  print("table.remove", table.remove(t))
  print("table.remove", next(t))
end

___''
do
  local p, t = tproxy{ 3, 1, 5, 2, 8, 5, 2, 9, 7, 4 }
  table.sort(p)
  print("table.sort", next(p))
  for i,v in ipairs(t) do
    print("table.sort", i, v)
  end
  table.sort(p)
  print("table.sort", next(p))
  for i,v in ipairs(t) do
    print("table.sort", i, v)
  end
  p, t = tproxy{ 9, 8, 7, 6, 5, 4, 3, 2, 1 }
  table.sort(p)
  print("table.sort", next(p))
  for i,v in ipairs(t) do
    print("table.sort", i, v)
  end
  table.sort(p, function(a, b) return a > b end)
  print("table.sort", next(p))
  for i,v in ipairs(t) do
    print("table.sort", i, v)
  end
  p, t = tproxy{ 1, 1, 1, 1, 1 }
  print("table.sort", next(p))
  for i,v in ipairs(t) do
    print("table.sort", i, v)
  end
  t = { 3, 1, 5, 2, 8, 5, 2, 9, 7, 4 }
  table.sort(t)
  for i,v in ipairs(t) do
    print("table.sort", i, v)
  end
  table.sort(t, function(a, b) return a > b end)
  for i,v in ipairs(t) do
    print("table.sort", i, v)
  end
end


___''
do
  local p, t = tproxy{ "a", "b", "c" }
  print("table.unpack", table.unpack(p))
  print("table.unpack", table.unpack(p, 2))
  print("table.unpack", table.unpack(p, 1, 2))
  print("table.unpack", table.unpack(t))
  print("table.unpack", table.unpack(t, 2))
  print("table.unpack", table.unpack(t, 1, 2))
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
print(mod.arith(2, 1))
print(mod.arith(3, 5))

___''
print(mod.compare(1, 1))
print(mod.compare(2, 1))
print(mod.compare(1, 2))

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

