local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local pairs = _tl_compat and _tl_compat.pairs or pairs; local table = _tl_compat and _tl_compat.table or table; local options = require('shiroko.options')
local common = require('shiroko.common')
local report = require('shiroko.report')
local visit = require('shiroko.visit')
local util = require('shiroko.util')
local fs = require('shiroko.fs')

local tl = require('tl')

local Node = common.Node

local stage = {
   rules = {

      require('shiroko.rules.adjacentOverloads'),
      require('shiroko.rules.caseStyle'),
      require('shiroko.rules.divideByZero'),
      require('shiroko.rules.emptyBlock'),
      require('shiroko.rules.globalUsage'),
      require('shiroko.rules.ifSameThenElse'),
      require('shiroko.rules.invalidPattern'),
      require('shiroko.rules.lineFormatting'),
      require('shiroko.rules.parenthesesDropped'),
      require('shiroko.rules.quoteStyle'),
      require('shiroko.rules.suspiciousReverseLoop'),
   },
   strategy = {},
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
            for kind, visitor in pairs(rule.visitorStrategy) do
               if stage.strategy[kind] then
                  table.insert((stage.strategy)[kind], visitor)
               else
                  (stage.strategy)[kind] = { visitor }
               end
            end
         end
      end
   end
end

function stage.process(file, env)
   local contents = fs.read(file)

   local root, reports, invalidSyntax = report(file, env)

   if invalidSyntax then
      return reports
   end

   local rets = reports

   local visitor = visit(root, stage.strategy, { env, file })

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

   return rets
end

return stage
