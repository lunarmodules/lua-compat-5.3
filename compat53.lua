local lua_version = _VERSION:sub(-3)

if lua_version ~= "5.3" then

   -- load utf8 library
   utf8 = require("compat53.utf8")
   package.loaded["utf8"] = utf8
   if lua_version == "5.1" then
      utf8.charpattern = "[%z\1-\127\194-\244][\128-\191]*"
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

end

