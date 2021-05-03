local common = require 'shiroko.common'
local util = require 'shiroko.util'

local function checkIf(node: common.Node): {common.Report}
   local branches = {}

   for i = 1, #node.if_blocks do
      local n = node.if_blocks[i].body
      table.insert(branches, {
         _str = util.stringify(n),
         message = 'If branch same as previous if',
         code = 'ifSameThenElse',
         severity = 'warning',
         column = n.x,
         line = n.y,
         columnStop = n.xend,
         lineStop = n.yend
      })
   end

   local ret = {}

   for i = 1, #branches do
      if branches[i - 1] and branches[i]._str == branches[i - 1]._str then
         table.insert(ret, branches[i])
      end
   end

   return #ret > 0 and util.mark(ret as {common.Report})
end

return util.rule {
   ruleset = 'recommended',
   visitorStrategy = {
      ['if'] = checkIf
   }
}
