local common = require 'shiroko.common'
local util = require 'shiroko.util'

local map: {string: string} = {
   global_function = 'function',
   local_function = 'function',
   if_block = 'if',
   fornum = 'for',
   forin = 'for'
}

local function checkBlock(node: common.Node): common.Report
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

      local fixes: any

      if node.kind ~= 'if_block' then -- The `else`
         -- TODO; support removing the `else` in front of `if` and that sort
         fixes = {
            {
               column = column,
               line = line,
               columnStop = columnStop,
               lineStop = lineStop,
               code = '' -- Just yeet it
            }
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
         fixes = fixes
      }
   end
end

return util.rule {
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
      forin = checkBlock
   }
}
