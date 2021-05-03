local patterns = require 'shiroko.patterns'
local common = require 'shiroko.common'
local util = require 'shiroko.util'

local tl = require 'tl'

local formatId: integer

local function checkFormat(node: common.Node, parent: common.Node, etc: {tl.Env, string}): common.Report
   if not formatId then
      formatId = util.typeid('string.format', etc[1])
   end

   if not node.type or node.type.typeid ~= formatId then
      return
   end

   local args = {}

   local pat: string

   for i, argument in ipairs(parent.e2) do
      if i == 1 and not argument.conststr then
         return
      end

      if i == 1 then
         pat = argument.conststr
      else
         table.insert(args, argument.type.typename)
      end
   end

   local parsed, errs = patterns.validateFormat(pat)

   local column, line, columnStop, lineStop =
      parent.e2.x,
      parent.e2.y,
      parent.e2.xend,
      parent.e2.yend

   if not parsed then
      local msg = table.concat(errs, ', ')

      return {
         message = msg:sub(0, 1):upper() .. msg:sub(2),
         code = 'invalidPattern',
         severity = 'error',
         column = column,
         line = line,
         columnStop = columnStop,
         lineStop = lineStop
      }
   end

   if #parsed > #args then
      return {
         message =
            'Expected ' .. #parsed .. ' argument' ..
            (#parsed == 1 and '' or 's') .. ', got ' ..
            #args .. ' argument' .. (#args == 1 and '' or 's'),
         code = 'invalidPattern',
         severity = 'error',
         column = column,
         line = line,
         columnStop = columnStop,
         lineStop = lineStop
      }
   end

   for i = 1, #parsed do
      if not util.union(parsed[i], args[i] as string) then
         return {
            message = 'Expected ' .. parsed[i] .. ' at argument ' .. (i + 1) .. ', got ' .. args[i],
            code = 'invalidPattern',
            severity = 'error',
            column = column,
            line = line,
            columnStop = columnStop,
            lineStop = lineStop
         }
      end
   end
end

return util.rule {
   ruleset = 'experimental',
   visitorStrategy = {
      op = checkFormat
   }
}
