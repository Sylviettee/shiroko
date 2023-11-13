local common = require('shiroko.common')
local util = require('shiroko.util')

local function checkOp(node)
   if node.e2 and node.e2.constnum == 0 and node.op.op == '/' then
      local column, line, columnStop, lineStop = 
      node.e1.x,
      node.e1.y,
      node.e2.x + #node.e2.tk,
      node.e2.y

      return {
         message = 'Dividing by zero is not allowed',
         code = 'divideByZero',
         severity = 'warning',
         column = column,
         line = line,
         columnStop = columnStop,
         lineStop = lineStop,
      }
   end
end

return util.rule({
   ruleset = 'recommended',
   visitorStrategy = {
      op = checkOp,
   },
})
