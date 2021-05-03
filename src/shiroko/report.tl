-- Generates a report from a... report
local common = require 'shiroko.common'

local tl = require 'tl'

local function automaticFix(err: tl.Error): common.Fix
   if err.msg:match('cannot apply pairs on values of type: %({.*}%)') then -- Array
      return {
         column = err.x - 5, -- Guessing...
         line = err.y,
         columnStop = err.x,
         lineStop = err.y,
         code = 'ipairs',
         experimental = true
      }
   end
end

local function isUselessHint(err: tl.Error): boolean
   if err.tag ~= 'hint' then
      return false
   end

   if err.msg == 'hint: applying pairs on an array: did you intend to apply ipairs?' then
      return true
   end
end

local function convertError(file: string, errs: {tl.Error}, ret: {common.Report}, level: string)
   if not errs then return end

   for i = 1, #errs do
      local err = errs[i]

      local report: common.Report = {
         file = err.filename or file,
         column = err.x,
         line = err.y,
         columnStop = err.xend or err.x, -- shiroko: allow(tlCheck)
         lineStop = err.yend or err.y, -- shiroko: allow(tlCheck)
         message = err.msg,
         severity = err.tag == 'hint' and 'hint' or (level as common.Severity) or 'error',
         code = err.tag or 'tlCheck'
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

local function generate(file: string, env: tl.Env): common.Node, {common.Report}, boolean
   local report = tl.process(file, env or tl.init_env(false, false, '5.3'))

   local invalidSyntax: boolean = false
   local reports: {common.Report} = {}

   if #report.syntax_errors > 0 then
      invalidSyntax = true

      convertError(file, report.syntax_errors, reports)
   end

   convertError(file, report.type_errors, reports)
   convertError(file, report.warnings, reports, 'warning')

   return report.ast as common.Node, reports, invalidSyntax
end

return generate
