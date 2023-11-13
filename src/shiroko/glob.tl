--[[
Copyright 2019 Hisham Muhammad

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]

-- code taken from Teal for globbing

local util = require 'shiroko.util'

local pathSeperator = package.config:sub(1, 1)

local function patternMatch(patt: {string}, str: string): boolean
   local matches = true
   local idx = 1

   local sIdx: integer

   for i = 1, #patt do
      sIdx, idx = str:find(patt[i], idx)

      if not sIdx then
         matches = false
         break
      end
   end

   return matches
end

local function matcher(str: string): function(string): boolean
   local chunks = {}
   local split = util.split(str, '**' .. pathSeperator)

   for i = 1, #split do
      table.insert(chunks, (split[i]:gsub('%*', '[^' .. pathSeperator .. ']-')))
   end

   chunks[1] = '^' .. chunks[1]
   chunks[#chunks] = chunks[#chunks] .. '$'

   return function(s: string): boolean
      return patternMatch(chunks, s)
   end
end

return function(files: {string}, glob: string): {string}
   local match = matcher(glob)
   local included = {}

   for i = 1, #files do
      if match(files[i]) then
         table.insert(included)
      end
   end

   return included
end
