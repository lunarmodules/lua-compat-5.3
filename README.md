# lua-compat-5.3

Lua-5.3-style APIs for Lua 5.2 and 5.1.

## What is it

This is a small module that aims to make it easier to write code
in a Lua-5.3-style that is compatible with Lua 5.1, Lua 5.2, and Lua
5.3. This does *not* make Lua 5.2 (or even Lua 5.1) entirely
compatible with Lua 5.3, but it brings the API closer to that of Lua
5.3.

It includes:

* _For writing Lua_: The Lua module `compat53`, which can be require'd
  from Lua scripts and run in Lua 5.1, 5.2, and 5.3, including a
  backport of the `utf8` module, the 5.3 `table` module, and the
  string packing functions straight from the Lua 5.3 sources.
* _For writing C_: A C header and file which can be linked to your
  Lua module written in C, providing some functions from the C API
  of Lua 5.3 that do not exist in Lua 5.2 or 5.1, making it easier to
  write C code that compiles with all three versions of liblua.

## How to use it

### Lua module

```lua
require("compat53")
```

`compat53` makes changes to your global environment and does not return
a meaningful return value, so the usual idiom of storing the return of
`require` in a local variable makes no sense.

When run under Lua 5.3, this module does nothing.

When run under Lua 5.2 or 5.1, it replaces some of your standard
functions and adds new ones to bring your environment closer to that
of Lua 5.3. It also tries to load the backported `utf8`, `table`, and
string packing modules automatically. If unsuccessful, pure Lua
versions of the new `table` functions are used as a fallback, and
[Roberto's struct library][1] is tried for string packing.

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

### Lua

* the `utf8` module backported from the Lua 5.3 sources
* `string.pack`, `string.packsize`, and `string.unpack` from the Lua
  5.3 sources or from the `struct` module. (`struct` is not 100%
  compatible to Lua 5.3's string packing!)
* `math.maxinteger` and `math.mininteger`, `math.tointeger`, `math.type`,
  and `math.ult`
* `ipairs` respects `__index` metamethod
* `table.move`
* `table` library respects metamethods

For Lua 5.1 additionally:
* `load` and `loadfile` accept `mode` and `env` parameters
* `table.pack` and `table.unpack`
* string patterns may contain embedded zeros
* `string.rep` accepts `sep` argument
* `string.format` calls `tostring` on arguments for `%s`
* `math.log` accepts base argument
* `xpcall` takes additional arguments
* `pcall` and `xpcall` can execute functions that yield
* `pairs` respects `__pairs` metamethod
* `rawlen` (but `#` still doesn't respect `__len` for tables)
* `package.searchers` as alias for `package.loaders`
* `package.searchpath`
* `coroutine` functions dealing with the main coroutine
* `coroutine.create` accepts functions written in C
* return code of `os.execute`
* `io.write` and `file:write` return file handle
* `io.lines` and `file:lines` accept format arguments (like `io.read`)
* `debug.setmetatable` returns object
* `debug.getuservalue` and `debug.setuservalue`

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
* `luaL_requiref` (now checks `package.loaded` first)
* `lua_rotate`
* `lua_stringtonumber`

For Lua 5.1 additionally:
* `LUA_OK`
* `LUA_OP*` macros for `lua_arith` and `lua_compare`
* `lua_Unsigned`
* `luaL_Stream`
* `LUA_FILEHANDLE`
* `lua_absindex`
* `lua_arith`
* `lua_compare`
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
* `luaL_buffinitsize`, `luaL_prepbuffsize`, and `luaL_pushresultsize`
* `lua_pushunsigned`, `lua_tounsignedx`, `lua_tounsigned`,
  `luaL_checkunsigned`, `luaL_optunsigned`, if
  `LUA_COMPAT_APIINTCASTS` is defined.

## What's not implemented

* bit operators
* integer division operator
* utf8 escape sequences
* 64 bit integers
* `coroutine.isyieldable`
* Lua 5.1: `_ENV`, `goto`, labels, ephemeron tables, etc. See
  [`lua-compat-5.2`][2] for a detailed list.
* the following C API functions/macros:
  * `lua_isyieldable`
  * `lua_getextraspace`
  * `lua_arith` (new operators missing)
  * `lua_push(v)fstring` (new formats missing)
  * `lua_upvalueid` (5.1)
  * `lua_upvaluejoin` (5.1)
  * `lua_version` (5.1)
  * `lua_yieldk` (5.1)
  * `luaL_execresult` (5.1)
  * `luaL_loadbufferx` (5.1)
  * `luaL_loadfilex` (5.1)

### Yieldable C functions

The emulation of `lua_(p)callk` for previous Lua versions is not 100%
perfect, because the continuation functions in Lua 5.2 have different
signatures than the ones in Lua 5.3 (and Lua 5.1 doesn't have
continuation functions at all). But with the help of a small macro the
same code can be used for all three Lua versions (the 5.1 version
won't support yielding though).

Original Lua 5.3 code (example adapted from the Lua 5.3 manual):

```C
static int k (lua_State *L, int status, lua_KContext ctx) {
  ...  /* code 2 */
}

int original_function (lua_State *L) {
  ...     /* code 1 */
  return k(L, lua_pcallk(L, n, m, h, ctx2, k), ctx1);
}
```

Portable version:

```C
LUA_KFUNCTION( k ) {
  ...  /* code 2; parameters L, status, and ctx available here */
}

int original_function (lua_State *L) {
  ...     /* code 1 */
  return k(L, lua_pcallk(L, n, m, h, ctx2, k), ctx1);
}
```

## See also

* For Lua-5.2-style APIs under Lua 5.1, see [lua-compat-5.2][2],
  which also is the basis for most of the code in this project.
* For Lua-5.1-style APIs under Lua 5.0, see [Compat-5.1][3]

## Credits

This package contains code written by:

* [The Lua Team](http://www.lua.org)
* Philipp Janda ([@siffiejoe](http://github.com/siffiejoe))
* Tomás Guisasola Gorham ([@tomasguisasola](http://github.com/tomasguisasola))
* Hisham Muhammad ([@hishamhm](http://github.com/hishamhm))
* Renato Maia ([@renatomaia](http://github.com/renatomaia))


  [1]: http://www.inf.puc-rio.br/~roberto/struct/
  [2]: http://github.com/keplerproject/lua-compat-5.2/
  [3]: http://keplerproject.org/compat/

