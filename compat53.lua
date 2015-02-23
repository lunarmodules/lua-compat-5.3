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
   local utf8_ok, utf8lib = pcall(require, "compat53.utf8")
   if utf8_ok then
      utf8 = utf8lib
      package.loaded["utf8"] = utf8lib
      if lua_version == "5.1" then
         utf8lib.charpattern = "[%z\1-\127\194-\244][\128-\191]*"
      end
   end


   -- load table library
   local table_ok, tablib = pcall(require, "compat53.table")
   if table_ok then
      for k,v in pairs(tablib) do
         table[k] = v
      end
   end


   -- load string packing functions
   local str_ok, strlib = pcall(require, "compat53.string")
   if str_ok then
      for k,v in pairs(strlib) do
         string[k] = v
      end
   end


   -- try Roberto's struct module for string packing/unpacking if
   -- compat53.string is unavailable
   if not str_ok then
      local struct_ok, struct = pcall(require, "struct")
      if struct_ok then
         string.pack = struct.pack
         string.packsize = struct.size
         string.unpack = struct.unpack
      end
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


   -- update table library (if C module not available)
   if not table_ok then
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

      do
         local function pivot(list, cmp, a, b)
            local m = b - a
            if m > 2 then
               local c = a + (m-m%2)/2
               local x, y, z = list[a], list[b], list[c]
               if not cmp(x, y) then
                  x, y, a, b = y, x, b, a
               end
               if not cmp(y, z) then
                  y, z, b, c = z, y, c, b
               end
               if not cmp(x, y) then
                  x, y, a, b = y, x, b, a
               end
               return b, y
            else
               return b, list[b]
            end
         end

         local function lt_cmp(a, b)
            return a < b
         end

         local function qsort(list, cmp, b, e)
            if b < e then
               local i, j, k, val = b, e, pivot(list, cmp, b, e)
               while i < j do
                  while i < j and cmp(list[i], val) do
                     i = i + 1
                  end
                  while i < j and not cmp(list[j], val) do
                     j = j - 1
                  end
                  if i < j then
                     list[i], list[j] = list[j], list[i]
                     if i == k then k = j end -- update pivot position
                     i, j = i+1, j-1
                  end
               end
               if i ~= k and not cmp(list[i], val) then
                  list[i], list[k] = val, list[i]
                  k = i -- update pivot position
               end
               qsort(list, cmp, b, i == k and i-1 or i)
               return qsort(list, cmp, i+1, e)
            end
         end

         local table_sort = table.sort
         function table.sort(list, cmp)
            local mt = gmt(list)
            local has_mt = type(mt) == "table"
            local has_len = has_mt and type(mt.__len) == "function"
            if has_len then
               cmp = cmp or lt_cmp
               local len = mt.__len(list)
               return qsort(list, cmp, 1, len)
            else
               return table_sort(list, cmp)
            end
         end
      end

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
   end -- update table library



   -- bring Lua 5.1 (and LuaJIT) up to speed with Lua 5.2
   if lua_version == "5.1" then
      -- detect LuaJIT (including LUAJIT_ENABLE_LUA52COMPAT compilation flag)
      local is_luajit = (string.dump(function() end) or ""):sub(1, 3) == "\027LJ"
      local is_luajit52 = is_luajit and
        #setmetatable({}, { __len = function() return 1 end }) == 1


      -- table that maps each running coroutine to the coroutine that resumed it
      -- this is used to build complete tracebacks when "coroutine-friendly" pcall
      -- is used.
      local pcall_previous = {}
      local pcall_callOf = {}
      local xpcall_running = {}
      local coroutine_running = coroutine.running

      -- handle debug functions
      if type(debug) == "table" then

         if not is_luajit52 then
            local _G, package = _G, package
            local debug_setfenv = debug.setfenv
            function debug.setuservalue(obj, value)
               if type(obj) ~= "userdata" then
                  error("bad argument #1 to 'setuservalue' (userdata expected, got "..
                        type(obj)..")", 2)
               end
               if value == nil then value = _G end
               if type(value) ~= "table" then
                  error("bad argument #2 to 'setuservalue' (table expected, got "..
                        type(value)..")", 2)
               end
               return debug_setfenv(obj, value)
            end

            local debug_getfenv = debug.getfenv
            function debug.getuservalue(obj)
               if type(obj) ~= "userdata" then
                  return nil
               else
                  local v = debug_getfenv(obj)
                  if v == _G or v == package then
                     return nil
                  end
                  return v
               end
            end

            local debug_setmetatable = debug.setmetatable
            function debug.setmetatable(value, tab)
               debug_setmetatable(value, tab)
               return value
            end
         end -- not luajit with compat52 enabled

         if not is_luajit then
            local debug_getinfo = debug.getinfo
            local function calculate_trace_level(co, level)
               if level ~= nil then
                  for out = 1, 1/0 do
                     local info = (co==nil) and debug_getinfo(out, "") or debug_getinfo(co, out, "")
                     if info == nil then
                        local max = out-1
                        if level <= max then
                           return level
                        end
                        return nil, level-max
                     end
                  end
               end
               return 1
            end

            local stack_pattern = "\nstack traceback:"
            local stack_replace = ""
            local debug_traceback = debug.traceback
            function debug.traceback(co, msg, level)
               local lvl
               local nilmsg
               if type(co) ~= "thread" then
                  co, msg, level = coroutine_running(), co, msg
               end
               if msg == nil then
                  msg = ""
                  nilmsg = true
               elseif type(msg) ~= "string" then
                  return msg
               end
               if co == nil then
                  msg = debug_traceback(msg, level or 1)
               else
                  local xpco = xpcall_running[co]
                  if xpco ~= nil then
                     lvl, level = calculate_trace_level(xpco, level)
                     if lvl then
                        msg = debug_traceback(xpco, msg, lvl)
                     else
                        msg = msg..stack_pattern
                     end
                     lvl, level = calculate_trace_level(co, level)
                     if lvl then
                        local trace = debug_traceback(co, "", lvl)
                        msg = msg..trace:gsub(stack_pattern, stack_replace)
                     end
                  else
                     co = pcall_callOf[co] or co
                     lvl, level = calculate_trace_level(co, level)
                     if lvl then
                        msg = debug_traceback(co, msg, lvl)
                     else
                        msg = msg..stack_pattern
                     end
                  end
                  co = pcall_previous[co]
                  while co ~= nil do
                     lvl, level = calculate_trace_level(co, level)
                     if lvl then
                        local trace = debug_traceback(co, "", lvl)
                        msg = msg..trace:gsub(stack_pattern, stack_replace)
                     end
                     co = pcall_previous[co]
                  end
               end
               if nilmsg then
                  msg = msg:gsub("^\n", "")
               end
               msg = msg:gsub("\n\t%(tail call%): %?", "\000")
               msg = msg:gsub("\n\t%.%.%.\n", "\001\n")
               msg = msg:gsub("\n\t%.%.%.$", "\001")
               msg = msg:gsub("(%z+)\001(%z+)", function(some, other)
                  return "\n\t(..."..#some+#other.."+ tail call(s)...)"
               end)
               msg = msg:gsub("\001(%z+)", function(zeros)
                  return "\n\t(..."..#zeros.."+ tail call(s)...)"
               end)
               msg = msg:gsub("(%z+)\001", function(zeros)
                  return "\n\t(..."..#zeros.."+ tail call(s)...)"
               end)
               msg = msg:gsub("%z+", function(zeros)
                  return "\n\t(..."..#zeros.." tail call(s)...)"
               end)
               msg = msg:gsub("\001", function(zeros)
                  return "\n\t..."
               end)
               return msg
            end
         end -- is not luajit
      end -- debug table available


      if not is_luajit52 then
         local _pairs = pairs
         function pairs(t)
            local mt = gmt(t)
            if type(mt) == "table" and type(mt.__pairs) == "function" then
               return mt.__pairs(t)
            else
               return _pairs(t)
            end
         end
      end


      if not is_luajit then
         local function check_mode(mode, prefix)
            local has = { text = false, binary = false }
            for i = 1,#mode do
               local c = mode:sub(i, i)
               if c == "t" then has.text = true end
               if c == "b" then has.binary = true end
            end
            local t = prefix:sub(1, 1) == "\27" and "binary" or "text"
            if not has[t] then
               return "attempt to load a "..t.." chunk (mode is '"..mode.."')"
            end
         end

         local setfenv = setfenv
         local _load, _loadstring = load, loadstring
         function load(ld, source, mode, env)
            mode = mode or "bt"
            local chunk, msg
            if type( ld ) == "string" then
               if mode ~= "bt" then
                  local merr = check_mode(mode, ld)
                  if merr then return nil, merr end
               end
               chunk, msg = _loadstring(ld, source)
            else
               local ld_type = type(ld)
               if ld_type ~= "function" then
                  error("bad argument #1 to 'load' (function expected, got "..
                        ld_type..")", 2)
               end
               if mode ~= "bt" then
                  local checked, merr = false, nil
                  local function checked_ld()
                     if checked then
                        return ld()
                     else
                        checked = true
                        local v = ld()
                        merr = check_mode(mode, v or "")
                        if merr then return nil end
                        return v
                     end
                  end
                  chunk, msg = _load(checked_ld, source)
                  if merr then return nil, merr end
               else
                  chunk, msg = _load(ld, source)
               end
            end
            if not chunk then
               return chunk, msg
            end
            if env ~= nil then
               setfenv(chunk, env)
            end
            return chunk
         end

         loadstring = load

         local _loadfile = loadfile
         local io_open = io.open
         function loadfile(file, mode, env)
            mode = mode or "bt"
            if mode ~= "bt" then
               local f = io_open(file, "rb")
               if f then
                  local prefix = f:read(1)
                  f:close()
                  if prefix then
                     local merr = check_mode(mode, prefix)
                     if merr then return nil, merr end
                  end
               end
            end
            local chunk, msg = _loadfile(file)
            if not chunk then
               return chunk, msg
            end
            if env ~= nil then
               setfenv(chunk, env)
            end
            return chunk
         end
      end -- not luajit


      if not is_luajit52 then
         function rawlen(v)
            local t = type(v)
            if t ~= "string" and t ~= "table" then
               error("bad argument #1 to 'rawlen' (table or string expected)", 2)
            end
            return #v
         end
      end


      if not is_luajit52 then
         local os_execute = os.execute
         function os.execute(cmd)
            local code = os_execute(cmd)
            -- Lua 5.1 does not report exit by signal.
            if code == 0 then
               return true, "exit", code
            else
               return nil, "exit", code/256 -- only correct on POSIX!
            end
         end
      end


      if not table_ok and not is_luajit52 then
         table.pack = function(...)
            return { n = select('#', ...), ... }
         end
      end


      local main_coroutine = coroutine.create(function() end)

      local _pcall = pcall
      local coroutine_create = coroutine.create
      function coroutine.create(func)
         local success, result = _pcall(coroutine_create, func)
         if not success then
            if type(func) ~= "function" then
               error("bad argument #1 (function expected)", 0)
             end
            result = coroutine_create(function(...) return func(...) end)
         end
         return result
      end

      local pcall_mainOf = {}

      if not is_luajit52 then
         function coroutine.running()
            local co = coroutine_running()
            if co then
               return pcall_mainOf[co] or co, false
            else
               return main_coroutine, true
            end
         end
      end

      local coroutine_yield = coroutine.yield
      function coroutine.yield(...)
         local co, flag = coroutine_running()
         if co and not flag then
            return coroutine_yield(...)
         else
            error("attempt to yield from outside a coroutine", 0)
         end
      end

      if not is_luajit then
         local coroutine_resume = coroutine.resume
         function coroutine.resume(co, ...)
            if co == main_coroutine then
               return false, "cannot resume non-suspended coroutine"
            else
               return coroutine_resume(co, ...)
            end
         end

         local coroutine_status = coroutine.status
         function coroutine.status(co)
            local notmain = coroutine_running()
            if co == main_coroutine then
               return notmain and "normal" or "running"
            else
               return coroutine_status(co)
            end
         end

         local function pcall_results(current, call, success, ...)
            if coroutine_status(call) == "suspended" then
               return pcall_results(current, call, coroutine_resume(call, coroutine_yield(...)))
            end
            if pcall_previous then
               pcall_previous[call] = nil
               local main = pcall_mainOf[call]
               if main == current then current = nil end
               pcall_callOf[main] = current
            end
            pcall_mainOf[call] = nil
            return success, ...
         end
         local function pcall_exec(current, call, ...)
            local main = pcall_mainOf[current] or current
            pcall_mainOf[call] = main
            if pcall_previous then
               pcall_previous[call] = current
               pcall_callOf[main] = call
            end
            return pcall_results(current, call, coroutine_resume(call, ...))
         end
         local coroutine_create52 = coroutine.create
         local function pcall_coroutine(func)
            if type(func) ~= "function" then
               local callable = func
               func = function (...) return callable(...) end
            end
            return coroutine_create52(func)
         end
         function pcall(func, ...)
            local current = coroutine_running()
            if not current then return _pcall(func, ...) end
            return pcall_exec(current, pcall_coroutine(func), ...)
         end

         local _tostring = tostring
         local function xpcall_catch(current, call, msgh, success, ...)
            if not success then
               xpcall_running[current] = call
               local ok, result = _pcall(msgh, ...)
               xpcall_running[current] = nil
               if not ok then
                  return false, "error in error handling (".._tostring(result)..")"
               end
               return false, result
            end
            return true, ...
         end
         local _xpcall = xpcall
         local _unpack = unpack
         function xpcall(f, msgh, ...)
            local current = coroutine_running()
            if not current then
               local args, n = { ... }, select('#', ...)
               return _xpcall(function() return f(_unpack(args, 1, n)) end, msgh)
            end
            local call = pcall_coroutine(f)
            return xpcall_catch(current, call, msgh, pcall_exec(current, call, ...))
         end
      end -- not luajit


      if not is_luajit then
         local math_log = math.log
         math.log = function(x, base)
            if base ~= nil then
               return math_log(x)/math_log(base)
            else
               return math_log(x)
            end
         end
      end


      local package = package
      if not is_luajit then
         local io_open = io.open
         local table_concat = table.concat
         function package.searchpath(name, path, sep, rep)
            sep = (sep or "."):gsub("(%p)", "%%%1")
            rep = (rep or package.config:sub(1, 1)):gsub("(%%)", "%%%1")
            local pname = name:gsub(sep, rep):gsub("(%%)", "%%%1")
            local msg = {}
            for subpath in path:gmatch("[^;]+") do
               local fpath = subpath:gsub("%?", pname)
               local f = io_open(fpath, "r")
               if f then
                  f:close()
                  return fpath
               end
               msg[#msg+1] = "\n\tno file '" .. fpath .. "'"
            end
            return nil, table_concat(msg)
         end
      end

      local p_index = { searchers = package.loaders }
      local rawset = rawset
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


      local string_gsub = string.gsub
      local function fix_pattern(pattern)
         return (string_gsub(pattern, "%z", "%%z"))
      end

      local string_find = string.find
      function string.find(s, pattern, ...)
         return string_find(s, fix_pattern(pattern), ...)
      end

      local string_gmatch = string.gmatch
      function string.gmatch(s, pattern)
         return string_gmatch(s, fix_pattern(pattern))
      end

      function string.gsub(s, pattern, ...)
         return string_gsub(s, fix_pattern(pattern), ...)
      end

      local string_match = string.match
      function string.match(s, pattern, ...)
         return string_match(s, fix_pattern(pattern), ...)
      end

      if not is_luajit then
         local string_rep = string.rep
         function string.rep(s, n, sep)
            if sep ~= nil and sep ~= "" and n >= 2 then
               return s .. string_rep(sep..s, n-1)
            else
               return string_rep(s, n)
            end
         end
      end

      if not is_luajit then
         local string_format = string.format
         do
            local addqt = {
               ["\n"] = "\\\n",
               ["\\"] = "\\\\",
               ["\""] = "\\\""
            }

            local function addquoted(c)
               return addqt[c] or string_format("\\%03d", c:byte())
            end

            local _unpack = unpack
            function string.format(fmt, ...)
               local args, n = { ... }, select('#', ...)
               local i = 0
               local function adjust_fmt(lead, mods, kind)
                  if #lead % 2 == 0 then
                     i = i + 1
                     if kind == "s" then
                        args[i] = tostring(args[i])
                     elseif kind == "q" then
                        args[i] = '"'..string_gsub(args[i], "[%z%c\\\"\n]", addquoted)..'"'
                        return lead.."%"..mods.."s"
                     end
                  end
               end
               fmt = string_gsub(fmt, "(%%*)%%([%d%.%-%+%# ]*)(%a)", adjust_fmt)
               return string_format(fmt, _unpack(args, 1, n))
            end
         end
      end


      local io_open = io.open
      local io_write = io.write
      local io_output = io.output
      function io.write(...)
         local res, msg, errno = io_write(...)
         if res then
            return io_output()
         else
            return nil, msg, errno
         end
      end

      if not is_luajit then
         local lines_iterator
         do
            local function helper( st, var_1, ... )
               if var_1 == nil then
                  if st.doclose then st.f:close() end
                  if (...) ~= nil then
                     error((...), 2)
                  end
               end
               return var_1, ...
            end

            local _unpack = unpack
            function lines_iterator(st)
               return helper(st, st.f:read(_unpack(st, 1, st.n)))
            end
         end

         local valid_format = { ["*l"] = true, ["*n"] = true, ["*a"] = true }

         local io_input = io.input
         function io.lines(fname, ...)
            local doclose, file, msg
            if fname ~= nil then
               doclose, file, msg = true, io_open(fname, "r")
               if not file then error(msg, 2) end
            else
               doclose, file = false, io_input()
            end
            local st = { f=file, doclose=doclose, n=select('#', ...), ... }
            for i = 1, st.n do
               if type(st[i]) ~= "number" and not valid_format[st[i]] then
                 error("bad argument #"..(i+1).." to 'for iterator' (invalid format)", 2)
               end
            end
            return lines_iterator, st
         end

         do
            local io_stdout = io.stdout
            local io_type = io.type
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
                  local st = { f=self, doclose=false, n=select('#', ...), ... }
                  for i = 1, st.n do
                     if type(st[i]) ~= "number" and not valid_format[st[i]] then
                        error("bad argument #"..(i+1).." to 'for iterator' (invalid format)", 2)
                     end
                  end
                  return lines_iterator, st
               end
            end
         end
      end -- not luajit


   end -- lua 5.1

end -- lua < 5.3

-- vi: set expandtab softtabstop=3 shiftwidth=3 :
