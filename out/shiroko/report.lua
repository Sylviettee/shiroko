local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local string = _tl_compat and _tl_compat.string or string; local table = _tl_compat and _tl_compat.table or table
local common = require('shiroko.common')

local tl = require('tl')

local function automaticFix(err)
   if err.msg:match('cannot apply pairs on values of type: %({.*}%)') then
      return {
         column = err.x - 5,
         line = err.y,
         columnStop = err.x,
         lineStop = err.y,
         code = 'ipairs',
         experimental = true,
      }
   end
end

local function isUselessHint(err)
   if err.tag ~= 'hint' then
      return false
   end

   if err.msg == 'hint: applying pairs on an array: did you intend to apply ipairs?' then
      return true
   end
end

local function convertError(file, errs, ret, level)
   if not errs then return end

   for i = 1, #errs do
      local err = errs[i]

      local report = {
         file = err.filename or file,
         column = err.x,
         line = err.y,
         columnStop = (err).xend or err.x,
         lineStop = (err).yend or err.y,
         message = err.msg,
         severity = err.tag == 'hint' and 'hint' or (level) or 'error',
         code = err.tag or 'tlCheck',
      }

      local fix = automaticFix(err)

      if fix then
         report.fixes = { fix }
      end

      if not isUselessHint(err) then
         table.insert(ret, report)
      end
   end
end

local function generate(file, env)
   local report = tl.process(file, env or tl.init_env(false, false, '5.3'))

   local invalidSyntax = false
   local reports = {}

   if #report.syntax_errors > 0 then
      invalidSyntax = true

      convertError(file, report.syntax_errors, reports)
   end

   convertError(file, report.type_errors, reports)
   convertError(file, report.warnings, reports, 'warning')

   return report.ast, reports, invalidSyntax
end

return generate
