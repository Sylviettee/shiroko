local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local table = _tl_compat and _tl_compat.table or table; local common = require('shiroko.common')
local util = require('shiroko.util')

local function checkIf(node)
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
         lineStop = n.yend,
      })
   end

   local ret = {}

   for i = 1, #branches do
      if branches[i - 1] and branches[i]._str == branches[i - 1]._str then
         table.insert(ret, branches[i])
      end
   end

   return #ret > 0 and util.mark(ret)
end

return util.rule({
   ruleset = 'recommended',
   visitorStrategy = {
      ['if'] = checkIf,
   },
})
