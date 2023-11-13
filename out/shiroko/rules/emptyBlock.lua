local common = require('shiroko.common')
local util = require('shiroko.util')

local map = {
   global_function = 'function',
   local_function = 'function',
   if_block = 'if',
   fornum = 'for',
   forin = 'for',
}

local function checkBlock(node)
   if #node.body == 0 then
      local kind = node.kind

      local column, line, columnStop, lineStop = 
      node.x,
      node.y,
      node.xend or node.body.x,
      node.yend or node.body.y

      if node.kind == 'if_block' then
         lineStop = node.yend
      end

      local fixes

      if node.kind ~= 'if_block' then

         fixes = {
            {
               column = column,
               line = line,
               columnStop = columnStop,
               lineStop = lineStop,
               code = '',
            },
         }
      end

      return {
         message = 'Empty ' .. (map[kind] and map[kind] or kind) .. ' block',
         code = 'emptyBlock',
         severity = 'warning',
         column = column,
         line = line,
         columnStop = columnStop,
         lineStop = lineStop,
         fixes = fixes,
      }
   end
end

return util.rule({
   ruleset = 'recommended',
   visitorStrategy = {
      ['do'] = checkBlock,
      if_block = checkBlock,
      ['while'] = checkBlock,
      ['repeat'] = checkBlock,
      ['function'] = checkBlock,
      local_function = checkBlock,
      global_function = checkBlock,
      fornum = checkBlock,
      forin = checkBlock,
   },
})
