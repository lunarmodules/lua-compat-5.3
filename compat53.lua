local lua_version = _VERSION:sub(-3)

if lua_version < "5.3" then
   -- local aliases for commonly used functions
   local type, select, error = type, select, error

   -- select the most powerful getmetatable function available
   local gmt = type(debug) == "table" and debug.getmetatable or
               getmetatable or function() return false end

   -- type checking functions
   local checkinteger -- forward declararation

   local function argcheck(cond, i, f, extra)
      if not cond then
         error("bad argument #"..i.." to '"..f.."' ("..extra..")", 0)
      end
   end

   local function checktype(x, t, i, f)
      local xt = type(x)
      if xt ~= t then
         error("bad argument #"..i.." to '"..f.."' ("..t..
               " expected, got "..xt..")", 0)
      end
   end


   -- load utf8 library
   local ok, utf8lib = pcall(require, "compat53.utf8")
   if ok then
      utf8 = utf8lib
      package.loaded["utf8"] = utf8lib
      if lua_version == "5.1" then
         utf8lib.charpattern = "[%z\1-\127\194-\244][\128-\191]*"
      end
   end


   -- use Roberto's struct module for string packing/unpacking for now
   -- maybe we'll later extract the functions from the 5.3 string
   -- library for greater compatiblity, but it uses the 5.3 buffer API
   -- which cannot easily be backported to Lua 5.1.
   local ok, struct = pcall(require, "struct")
   if ok then
      string.pack = struct.pack
      string.packsize = struct.size
      string.unpack = struct.unpack
   end


   -- update math library
   do
      local maxint, minint = 1, 0

      while maxint+1 > maxint and 2*maxint > maxint do
         maxint = maxint * 2
      end
      if 2*maxint <= maxint then
         maxint = 2*maxint-1
         minint = -maxint-1
      else
         maxint = maxint
         minint = -maxint
      end
      math.maxinteger = maxint
      math.mininteger = minint

      function math.tointeger(n)
         if type(n) == "number" and n <= maxint and n >= minint and n % 1 == 0 then
            return n
         end
         return nil
      end

      function math.type(n)
         if type(n) == "number" then
            if n <= maxint and n >= minint and n % 1 == 0 then
               return "integer"
            else
               return "float"
            end
         else
            return nil
         end
      end

      function checkinteger(x, i, f)
         local t = type(x)
         if t ~= "number" then
            error("bad argument #"..i.." to '"..f..
                  "' (number expected, got "..t..")", 0)
         elseif x > maxint or x < minint or x % 1 ~= 0 then
            error("bad argument #"..i.." to '"..f..
                  "' (number has no integer representation)", 0)
         else
            return x
         end
      end

      function math.ult(m, n)
         m = checkinteger(m, "1", "math.ult")
         n = checkinteger(n, "2", "math.ult")
         if m >= 0 and n < 0 then
            return true
         elseif m < 0 and n >= 0 then
            return false
         else
            return m < n
         end
      end
   end


   -- ipairs should respect __index metamethod
   do
      local _ipairs = ipairs
      local function ipairs_iterator(st, var)
         var = var + 1
         local val = st[var]
         if val ~= nil then
            return var, st[var]
         end
      end
      function ipairs(t)
         if gmt(t) ~= nil then -- t has metatable
            return ipairs_iterator, t, 0
         else
            return _ipairs(t)
         end
      end
   end


   -- update table library
   do
      local table_concat = table.concat
      function table.concat(list, sep, i, j)
         local mt = gmt(list)
         if type(mt) == "table" and type(mt.__len) == "function" then
            local src = list
            list, i, j  = {}, i or 1, j or mt.__len(src)
            for k = i, j do
               list[k] = src[k]
            end
         end
         return table_concat(list, sep, i, j)
      end

      local table_insert = table.insert
      function table.insert(list, ...)
         local mt = gmt(list)
         local has_mt = type(mt) == "table"
         local has_len = has_mt and type(mt.__len) == "function"
         if has_mt and (has_len or mt.__index or mt.__newindex) then
            local e = (has_len and mt.__len(list) or #list)+1
            local nargs, pos, value = select('#', ...), ...
            if nargs == 1 then
               pos, value = e, pos
            elseif nargs == 2 then
               pos = checkinteger(pos, "2", "table.insert")
               argcheck(1 <= pos and pos <= e, "2", "table.insert",
                        "position out of bounds" )
            else
               error("wrong number of arguments to 'insert'", 0)
            end
            for i = e-1, pos, -1 do
               list[i+1] = list[i]
            end
            list[pos] = value
         else
            return table_insert(list, ...)
         end
      end

      function table.move(a1, f, e, t, a2)
         a2 = a2 or a1
         f = checkinteger(f, "2", "table.move")
         argcheck(f > 0, "2", "table.move",
                  "initial position must be positive")
         e = checkinteger(e, "3", "table.move")
         t = checkinteger(t, "4", "table.move")
         if e >= f then
            local m, n, d = 0, e-f, 1
            if t > f then m, n, d = n, m, -1 end
            for i = m, n, d do
               a2[t+i] = a1[f+i]
            end
         end
         return a2
      end

      local table_remove = table.remove
      function table.remove(list, pos)
         local mt = gmt(list)
         local has_mt = type(mt) == "table"
         local has_len = has_mt and type(mt.__len) == "function"
         if has_mt and (has_len or mt.__index or mt.__newindex) then
            local e = (has_len and mt.__len(list) or #list)
            pos = pos ~= nil and checkinteger(pos, "2", "table.remove") or e
            if pos ~= e then
               argcheck(1 <= pos and pos <= e+1, "2", "table.remove",
                        "position out of bounds" )
            end
            local result = list[pos]
            while pos < e do
               list[pos] = list[pos+1]
               pos = pos + 1
            end
            list[pos] = nil
            return result
         else
            return table_remove(list, pos)
         end
      end

      -- TODO: table.sort

      local table_unpack = lua_version == "5.1" and unpack or table.unpack
      local function unpack_helper(list, i, j, ...)
         if j < i then
            return ...
         else
            return unpack_helper(list, i, j-1, list[j], ...)
         end
      end
      function table.unpack(list, i, j)
         local mt = gmt(list)
         local has_mt = type(mt) == "table"
         local has_len = has_mt and type(mt.__len) == "function"
         if has_mt and (has_len or mt.__index) then
            i, j = i or 1, j or (has_len and mt.__len(list)) or #list
            return unpack_helper(list, i, j)
         else
            return table_unpack(list, i, j)
         end
      end
   end


   if lua_version == "5.1" then
      -- detect LuaJIT (including LUAJIT_ENABLE_LUA52COMPAT compilation flag)
      local is_luajit = (string.dump(function() end) or ""):sub(1, 3) == "\027LJ"
      local is_luajit52 = is_luajit and
        #setmetatable({}, { __len = function() return 1 end }) == 1

      -- TODO: add functions from lua-compat-5.2

   end

end

-- vi: set expandtab softtabstop=3 shiftwidth=3 :
