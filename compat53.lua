local lua_version = _VERSION:sub(-3)

if lua_version ~= "5.3" then

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

      local _type = type
      function math.tointeger(n)
         if _type(n) == "number" and n <= maxint and n >= minint and n % 1 == 0 then
            return n
         end
         return nil
      end

      function math.type(n)
         if _type(n) == "number" then
            if n <= maxint and n >= minint and n % 1 == 0 then
               return "integer"
            else
               return "float"
            end
         else
            return nil
         end
      end

      local _error = error
      local function checkinteger(x, i, f)
         local t = _type(x)
         if t ~= "number" then
            _error("bad argument #"..i.." to '"..f..
                   "' (number expected, got "..t..")", 0)
         elseif x > maxint or x < minint or x % 1 ~= 0 then
            _error("bad argument #"..i.." to '"..f..
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

end

-- vi: set expandtab softtabstop=3 shiftwidth=3 :
