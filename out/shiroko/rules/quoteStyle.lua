local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local string = _tl_compat and _tl_compat.string or string; local options = require('shiroko.options')
local common = require('shiroko.common')
local util = require('shiroko.util')

local function checkQuotes(node, parent)
   if parent.kind == 'table_item' and node.is_longstring == nil then
      return
   end

   if node.is_longstring then
      return
   end

   local quote = options.quoteStyle == 'single' and '\'' or '"'
   local opp = options.quoteStyle == 'single' and '"' or '\''

   local human = options.quoteStyle == 'single' and 'double' or 'single'

   if node.tk:sub(1, 1) == opp and not node.tk:find(quote) then
      local column, line, columnStop, lineStop = 
      node.x,
      node.y,
      #node.tk + node.x,
      util.countChars(node.tk, '\n') + node.y

      return {
         message = 'Expected ' .. options.quoteStyle .. ' quotes, got ' .. human .. ' quotes',
         severity = 'style',
         code = 'quoteStyle',
         column = column,
         line = line,
         columnStop = columnStop,
         lineStop = lineStop,
         fixes = {
            {
               column = column,
               line = line,
               columnStop = columnStop,
               lineStop = lineStop,
               code = quote .. node.tk:sub(2, #node.tk - 1) .. quote,
            },
         },
      }
   end
end

return util.rule({
   ruleset = 'luarocks-modified',
   visitorStrategy = {
      string = checkQuotes,
      enum_item = checkQuotes,
   },
})
