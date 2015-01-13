# lua-compat-5.3

Lua-5.3-style APIs for Lua 5.2 and 5.1.

## What is it

This is a small module that aims to make it easier to write code
in a Lua-5.3-style that is compatible with Lua 5.1, Lua 5.2, and Lua
5.3. This does *not* make Lua 5.2 (or even Lua 5.1) entirely
compatible with Lua 5.3, but it brings the API closer to that of Lua
5.3.

It includes:

* _For writing C_: A C header and file which can be linked to your
  Lua module written in C, providing some functions from the C API
  of Lua 5.3 that do not exist in Lua 5.2 or 5.1, making it easier to
  write C code that compiles with all three versions of liblua.

## How to use it

### C code

There are two ways of adding the C API compatibility functions/macros to
your project:
* If `COMPAT53_PREFIX` is *not* `#define`d, `compat-5.3.h` `#include`s
  `compat-5.3.c`, and all functions are made `static`. You don't have to
  compile/link/add `compat-5.3.c` yourself. This is useful for one-file
  projects.
* If `COMPAT53_PREFIX` is `#define`d, all exported functions are renamed
  behind the scenes using this prefix to avoid linker conflicts with other
  code using this package. This doesn't change the way you call the
  compatibility functions in your code. You have to compile and link
  `compat-5.3.c` to your project yourself. You can change the way the
  functions are exported using the `COMPAT53_API` macro (e.g. if you need
  some `__declspec` magic).

## What's implemented

### C

* `lua_KContext`
* `lua_KFunction`
* `lua_dump` (extra `strip` parameter, ignored)
* `lua_getfield` (return value)
* `lua_geti` and `lua_seti`
* `lua_getglobal` (return value)
* `lua_getmetafield` (return value)
* `lua_gettable` (return value)
* `lua_getuservalue` and `lua_setuservalue` (limited compatibility)
* `lua_isinteger`
* `lua_numbertointeger`
* `lua_callk` and `lua_pcallk` (limited compatibility)
* `lua_rawget` and `lua_rawgeti` (return values)
* `lua_rawgetp` and `lua_rawsetp`
* `luaL_requiref` (now checks `package.loaded`)
* `lua_rotate`
* `lua_stringtonumber`

For Lua 5.1 additionally:
* `LUA_OK`
* `lua_Unsigned`
* `luaL_Stream`
* `LUA_FILEHANDLE`
* `lua_absindex`
* `lua_len`, `lua_rawlen`, and `luaL_len`
* `lua_copy`
* `lua_pushglobaltable`
* `luaL_testudata`
* `luaL_setfuncs`, `luaL_newlibtable`, and `luaL_newlib`
* `luaL_setmetatable`
* `luaL_getsubtable`
* `luaL_traceback`
* `luaL_fileresult`
* `luaL_checkversion` (with empty body, only to avoid compile errors)
* `luaL_tolstring`
* `lua_pushunsigned`, `lua_tounsignedx`, `lua_tounsigned`,
  `luaL_checkunsigned`, `luaL_optunsigned`, if
  `LUA_COMPAT_APIINTCASTS` is defined.

## What's not implemented

* the new Lua functions of Lua 5.3
* the table library doesn't respect metamethods yet
* the utf8 library
* string packing/unpacking
* Lua 5.1: `_ENV`, `goto`, labels, ephemeron tables, etc.
* the following C API functions/macros:
  * `lua_isyieldable`
  * `lua_getextraspace`
  * `lua_arith` (not at all in 5.1, operators missing in 5.2)
  * `lua_pushfstring` (new formats)
  * `lua_compare` (5.1)
  * `lua_upvalueid` (5.1)
  * `lua_upvaluejoin` (5.1)
  * `lua_version` (5.1)
  * `lua_yieldk` (5.1)
  * `luaL_buffinitsize` (5.1)
  * `luaL_execresult` (5.1)
  * `luaL_loadbufferx` (5.1)
  * `luaL_loadfilex` (5.1)
  * `luaL_prepbuffsize` (5.1)
  * `luaL_pushresultsize` (5.1)

## See also

* For Lua-5.2-style APIs under Lua 5.1, see
[lua-compat-5.2](http://github.com/keplerproject/lua-compat-5.2/),
which also is the basis for most of the code in this project.
* For Lua-5.1-style APIs under Lua 5.0, see
[Compat-5.1](http://keplerproject.org/compat/)

## Credits

This package contains code written by:

* [The Lua Team](http://www.lua.org)
* Philipp Janda ([@siffiejoe](http://github.com/siffiejoe))
* Tomás Guisasola Gorham ([@tomasguisasola](http://github.com/tomasguisasola))
* Hisham Muhammad ([@hishamhm](http://github.com/hishamhm))
* Renato Maia ([@renatomaia](http://github.com/renatomaia))

