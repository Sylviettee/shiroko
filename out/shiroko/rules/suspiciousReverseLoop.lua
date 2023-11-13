local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local string = _tl_compat and _tl_compat.string or string; local common = require('shiroko.common')
local util = require('shiroko.util')

local reverseLoop = util.quote([[
for _ = 1, 2, -1 do
end
]])[1]

local function checkFor(node)
   local to = node.to
   local from = node.from
   local step = node.step

   local isReverseLoop = 
   (to.constnum and from.constnum and from.constnum > to.constnum) and
   not (step and step.op.op == '-')

   if not isReverseLoop and not (step and step.op.op == '-') then
      isReverseLoop = from.op and from.op.op == '#' and to.constnum == 1
   end

   if isReverseLoop then
      local oldBody = node.body
      node.step = reverseLoop.step
      node.body = reverseLoop.body

      local code = util.stringify(node)

      code = code:sub(from.x, #code - 7)

      node.body = oldBody
      node.step = nil

      local column, line, columnStop, lineStop = 
      from.x,
      from.y,
      to.x + #to.tk,
      to.y

      return {
         message = 'Suspicious reverse loop',
         code = 'suspiciousReverseLoop',
         severity = 'warning',
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
               code = code,
            },
         },
      }
   end
end

return util.rule({
   ruleset = 'recommended',
   visitorStrategy = {
      fornum = checkFor,
   },
})
