local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local string = _tl_compat and _tl_compat.string or string; local table = _tl_compat and _tl_compat.table or table; local options = require('shiroko.options')
local common = require('shiroko.common')
local util = require('shiroko.util')

local function checkLine(line, lineNum)
   local rets = {}

   if #line > options.lineLength then
      table.insert(rets, {
         message = 'Line is too long (' .. #line .. ' > ' .. options.lineLength .. ')',
         code = 'lineLength',
         severity = 'style',
         column = options.lineLength,
         line = lineNum,
         columnStop = #line,
         lineStop = lineNum,
      })
   end

   do
      local indent, stop = line:match('^(%s*)()')

      local char = indent:sub(1, 1)
      local opp = char == ' ' and '\t' or ' '

      local oppIndentation = options.indentation == 'space' and '\t' or ' '
      local oppName = options.indentation == 'space' and 'tab' or 'space'
      local indentation = options.indentation == 'space' and ' ' or '\t'

      local fix = {
         column = 1,
         line = lineNum,
         columnStop = stop,
         lineStop = lineNum,
         code = indent:gsub(
         indentation == ' ' and '\t' or string.rep(' ', options.indentationSize),
         indentation == ' ' and string.rep(' ', options.indentationSize) or '\t'),

      }

      if indentation == '\t' then
         fix.code = fix.code:gsub(' ', '')
      end

      if indent:find(opp, 1, true) then
         table.insert(rets, {
            message = 'Inconsistent indentation',
            code = 'invalidWhitespace',
            severity = 'warning',
            column = 1,
            line = lineNum,
            columnStop = stop,
            lineStop = lineNum,
            fixes = {
               fix,
            },
         })
      end

      if indent:find(oppIndentation, 1, true) then
         table.insert(rets, {
            message = 'Indentation should not be made up of ' .. oppName .. 's',
            code = 'invalidWhitespace',
            severity = 'warning',
            column = 1,
            line = lineNum,
            columnStop = stop,
            lineStop = lineNum,
            fixes = {
               fix,
            },
         })
      end
   end

   local start, stop = line:match('^()%s+()$')

   if start and stop then
      table.insert(rets, {
         message = 'Line consists of only whitespace',
         code = 'invalidWhitespace',
         severity = 'warning',
         column = start,
         line = lineNum,
         columnStop = stop,
         lineStop = lineNum,
         fixes = {
            {
               column = start,
               line = lineNum,
               columnStop = stop,
               lineStop = lineNum,
               code = '',
            },
         },
      })

      return rets
   else
      start, stop = line:match('^.-()%s+()$')
   end

   if start and stop then
      table.insert(rets, {
         message = 'Tailing whitespace',
         code = 'invalidWhitespace',
         severity = 'warning',
         column = start,
         line = lineNum,
         columnStop = stop,
         lineStop = lineNum,
         fixes = {
            {
               column = start,
               line = lineNum,
               columnStop = stop,
               lineStop = lineNum,
               code = line:sub(0, start - 1),
            },
         },
      })
   end

   return rets
end

local function main(_node, contents)
   local reports2d = util.walkLines(contents, checkLine)
   return util.flatten(reports2d)
end

return util.rule({
   ruleset = 'recommended',
   lintProgram = main,
})
