#!/usr/bin/env lua

local mod = require( "testmod" )
local F
do
  local type, unpack = type, table.unpack or unpack
  function F( ... )
    local args, n = { ... }, select( '#', ... )
    for i = 1, n do
      local t = type( args[ i ] )
      if t ~= "string" and t ~= "number" and t ~= "boolean" then
        args[ i ] = t
      end
    end
    return unpack( args, 1, n )
  end
end


print( mod.isinteger( 1 ) )
print( mod.isinteger( 0 ) )
print( mod.isinteger( 1234567 ) )
print( mod.isinteger( 12.3 ) )
print( mod.isinteger( math.huge ) )
print( mod.isinteger( math.sqrt( -1 ) ) )


print( mod.rotate( 1, 1, 2, 3, 4, 5, 6 ) )
print( mod.rotate(-1, 1, 2, 3, 4, 5, 6 ) )
print( mod.rotate( 4, 1, 2, 3, 4, 5, 6 ) )
print( mod.rotate( -4, 1, 2, 3, 4, 5, 6 ) )


print( mod.strtonum( "+123" ) )
print( mod.strtonum( " 123 " ) )
print( mod.strtonum( "-1.23" ) )
print( mod.strtonum( " 123 abc" ) )
print( mod.strtonum( "jkl" ) )


local a, b, c = mod.requiref()
print( type( a ), type( b ), type( c ),
       a.boolean, b.boolean, c.boolean,
       type( requiref1 ), type( requiref2 ), type( requiref3 ) )

local proxy, backend = {}, {}
setmetatable( proxy, { __index = backend, __newindex = backend } )
print( rawget( proxy, 1 ), rawget( backend, 1 ) )
print( mod.getseti( proxy, 1 ) )
print( rawget( proxy, 1 ), rawget( backend, 1 ) )
print( mod.getseti( proxy, 1 ) )
print( rawget( proxy, 1 ), rawget( backend, 1 ) )

-- tests for Lua 5.1
print(mod.tonumber(12))
print(mod.tonumber("12"))
print(mod.tonumber("0"))
print(mod.tonumber(false))
print(mod.tonumber("error"))

print(mod.tointeger(12))
print(mod.tointeger("12"))
print(mod.tointeger("0"))
print( "aaa" )
print(mod.tointeger(math.pi))
print( "bbb" )
print(mod.tointeger(false))
print(mod.tointeger("error"))

print(mod.len("123"))
print(mod.len({ 1, 2, 3}))
print(pcall(mod.len, true))
local ud, meta = mod.newproxy()
meta.__len = function() return 5 end
print(mod.len(ud))
meta.__len = function() return true end
print(pcall(mod.len, ud))

print(mod.copy(true, "string", {}, 1))

print(mod.rawxetp())
print(mod.rawxetp("I'm back"))

print(F(mod.globals()), mod.globals() == _G)

local t = {}
print(F(mod.subtable(t)))
local x, msg = mod.subtable(t)
print(F(x, msg, x == t.xxx))

print(F(mod.udata()))
print(mod.udata("nosuchtype"))

print(F(mod.uservalue()))

print(mod.getupvalues())

print(mod.absindex("hi", true))

print(mod.tolstring("string"))
local t = setmetatable({}, {
  __tostring = function(v) return "mytable" end
})
print(mod.tolstring( t ) )
local t = setmetatable({}, {
  __tostring = function(v) return nil end
})
print(pcall(mod.tolstring, t))

