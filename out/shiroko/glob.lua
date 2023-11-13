local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local package = _tl_compat and _tl_compat.package or package; local string = _tl_compat and _tl_compat.string or string; local table = _tl_compat and _tl_compat.table or table























local util = require('shiroko.util')

local pathSeperator = package.config:sub(1, 1)

local function patternMatch(patt, str)
   local matches = true
   local idx = 1

   local sIdx

   for i = 1, #patt do
      sIdx, idx = str:find(patt[i], idx)

      if not sIdx then
         matches = false
         break
      end
   end

   return matches
end

local function matcher(str)
   local chunks = {}
   local split = util.split(str, '**' .. pathSeperator)

   for i = 1, #split do
      table.insert(chunks, (split[i]:gsub('%*', '[^' .. pathSeperator .. ']-')))
   end

   chunks[1] = '^' .. chunks[1]
   chunks[#chunks] = chunks[#chunks] .. '$'

   return function(s)
      return patternMatch(chunks, s)
   end
end

return function(files, glob)
   local match = matcher(glob)
   local included = {}

   for i = 1, #files do
      if match(files[i]) then
         table.insert(included)
      end
   end

   return included
end
