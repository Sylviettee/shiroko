local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local string = _tl_compat and _tl_compat.string or string; local table = _tl_compat and _tl_compat.table or table; local patterns = require('shiroko.patterns')
local common = require('shiroko.common')
local util = require('shiroko.util')

local tl = require('tl')

local formatId

local function checkFormat(node, parent, etc)
   if not formatId then
      formatId = util.typeid('string.format', etc[1])
   end

   if not node.type or node.type.typeid ~= formatId then
      return
   end

   local args = {}

   local pat

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
         lineStop = lineStop,
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
         lineStop = lineStop,
      }
   end

   for i = 1, #parsed do
      if not util.union(parsed[i], args[i]) then
         return {
            message = 'Expected ' .. parsed[i] .. ' at argument ' .. (i + 1) .. ', got ' .. args[i],
            code = 'invalidPattern',
            severity = 'error',
            column = column,
            line = line,
            columnStop = columnStop,
            lineStop = lineStop,
         }
      end
   end
end

return util.rule({
   ruleset = 'experimental',
   visitorStrategy = {
      op = checkFormat,
   },
})
