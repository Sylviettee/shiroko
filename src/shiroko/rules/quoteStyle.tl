local options = require 'shiroko.options'
local common = require 'shiroko.common'
local util = require 'shiroko.util'

local function checkQuotes(node: common.Node, parent: common.Node): common.Report
   if parent.kind == 'table_item' and node.is_longstring == nil then -- x = 5 and not ['x'] = 5
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
               code = quote .. node.tk:sub(2, #node.tk - 1) .. quote
            }
         }
      }
   end
end

return util.rule {
   ruleset = 'luarocks-modified',
   visitorStrategy = {
      string = checkQuotes,
      enum_item = checkQuotes
   }
}
