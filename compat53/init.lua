local _G, _VERSION, type, pairs, require =
      _G, _VERSION, type, pairs, require

local M = require("compat53.base")
local lua_version = _VERSION:sub(-3)


-- apply other global effects
if lua_version == "5.1" then

   -- cache globals
   local error, rawset, select, setmetatable, type, unpack =
         error, rawset, select, setmetatable, type, unpack
   local debug, io, package, string = debug, io, package, string
   local io_type, io_stdout = io.type, io.stdout

   -- select the most powerful getmetatable function available
   local gmt = type(debug) == "table" and debug.getmetatable or
               getmetatable or function() return false end

   -- detect LuaJIT (including LUAJIT_ENABLE_LUA52COMPAT compilation flag)
   local is_luajit = (string.dump(function() end) or ""):sub(1, 3) == "\027LJ"


   -- make package.searchers available as an alias for package.loaders
   local p_index = { searchers = package.loaders }
   setmetatable(package, {
      __index = p_index,
      __newindex = function(p, k, v)
         if k == "searchers" then
            rawset(p, "loaders", v)
            p_index.searchers = v
         else
            rawset(p, k, v)
         end
      end
   })


   if not is_luajit then
      local function helper(st, var_1, ...)
         if var_1 == nil then
            if (...) ~= nil then
               error((...), 2)
            end
         end
         return var_1, ...
      end

      local function lines_iterator(st)
         return helper(st, st.f:read(unpack(st, 1, st.n)))
      end

      local valid_format = { ["*l"] = true, ["*n"] = true, ["*a"] = true }

      local file_meta = gmt(io_stdout)
      if type(file_meta) == "table" and type(file_meta.__index) == "table" then
         local file_write = file_meta.__index.write
         file_meta.__index.write = function(self, ...)
            local res, msg, errno = file_write(self, ...)
            if res then
               return self
            else
               return nil, msg, errno
            end
         end

         file_meta.__index.lines = function(self, ...)
            if io_type(self) == "closed file" then
               error("attempt to use a closed file", 2)
            end
            local st = { f=self, n=select('#', ...), ... }
            for i = 1, st.n do
               if type(st[i]) ~= "number" and not valid_format[st[i]] then
                  error("bad argument #"..(i+1).." to 'for iterator' (invalid format)", 2)
               end
            end
            return lines_iterator, st
         end
      end
   end -- not luajit

end -- lua == 5.1


-- handle exporting to global scope
local function extend_table(from, to)
   for k,v in pairs(from) do
      if type(v) == "table" and
         type(to[k]) == "table" and
         v ~= to[k] then
         extend_table(v, to[k])
      else
         to[k] = v
      end
   end
end

extend_table(M, _G)

return _G

-- vi: set expandtab softtabstop=3 shiftwidth=3 :
