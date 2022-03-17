local options = require 'shiroko.options'
local common = require 'shiroko.common'
local util = require 'shiroko.util'

local function checkParentheses(node: common.Node): common.Report
   if node.op.op ~= '@funcall' then
      return
   end

   local e1, e2 = node.e1, node.e2

   if e2.tk == '(' then
      return
   end

   if e2.tk == '{' and options.allowTableDrop then
      return
   end

   if options.allowRequireDrop
      and e1.kind == 'variable' and e1.tk == 'require'
      and e2.kind == 'expression_list' and #e2 == 1
      and e2[1].kind == 'string'
   then
      return
   end

   return {
      message = 'Parentheses should not be omitted when calling functions',
      code = 'parenthesesDropped',
      severity = 'style',
      column = node.x,
      line = node.y
   }
end

return util.rule {
   ruleset = 'luarocks-modified',
   visitorStrategy = {
      op = checkParentheses
   }
}
