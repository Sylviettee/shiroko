local options = require 'shiroko.options'
local common = require 'shiroko.common'
local report = require 'shiroko.report'
local visit = require 'shiroko.visit'
local util = require 'shiroko.util'
local fs = require 'shiroko.fs'

local tl = require 'tl'

local Node = common.Node -- shiroko: allow(caseStyle)

local stage = {
   rules: {common.Rule} = { -- Overhead of `load` and recursive directory search can be a bit
      --; TODO - only load rules that are allowed
      require 'shiroko.rules.adjacentOverloads',
      require 'shiroko.rules.caseStyle',
      require 'shiroko.rules.divideByZero',
      require 'shiroko.rules.emptyBlock',
      require 'shiroko.rules.globalUsage',
      require 'shiroko.rules.ifSameThenElse',
      require 'shiroko.rules.invalidPattern',
      require 'shiroko.rules.lineFormatting',
      require 'shiroko.rules.parenthesesDropped',
      require 'shiroko.rules.quoteStyle',
      require 'shiroko.rules.suspiciousReverseLoop'
   },
   strategy: {string: {function(Node, Node, common.etc): common.Report}} = {}
}

function stage.generateStrategy()
   stage.strategy = {}

   local values = {}

   for i = 1, #options.rulesets do
      values[options.rulesets[i]] = true
   end

   for i = 1, #stage.rules do
      local rule = stage.rules[i]

      if values[rule.ruleset] then
         if rule.visitorStrategy then
            for kind, visitor in pairs(rule.visitorStrategy as {string: any}) do
               if stage.strategy[kind] then
                  table.insert((stage.strategy as {string: {any}})[kind], visitor)
               else
                  (stage.strategy as {string: any})[kind] = { visitor }
               end
            end
         end
      end
   end
end

function stage.process(file: string, env: tl.Env): {common.Report}
   local contents = fs.read(file)

   local root, reports, invalidSyntax = report(file, env)

   if invalidSyntax then
      return reports
   end

   local rets = reports

   local visitor = visit(root, stage.strategy, {env, file})

   util.tblMerge(rets, visitor)

   for i = 1, #stage.rules do
      local rule = stage.rules[i]

      if rule.lintProgram then
         local ret = rule.lintProgram(root, contents)

         for k = 1, #ret do
            table.insert(rets, ret[k])
         end
      end
   end

   for i = 1, #rets do
      local ret = rets[i]

      ret.file = ret.file or file

      if ret.fixes then
         for k = 1, #ret.fixes do
            ret.fixes[k].file = ret.fixes[k].file or file
         end
      end
   end

   return rets -- rets
end

return stage
