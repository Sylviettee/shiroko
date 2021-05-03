local common = require 'shiroko.common'
local util = require 'shiroko.util'

local function checkParentheses(node: common.Node): common.Report
   if node.op.op ~= '@funcall' then
      return
   end

   if node.e2.tk ~= '(' then
      return {
         message = 'Parentheses should not be omitted when calling functions',
         code = 'parenthesesDropped',
         severity = 'style',
         column = node.x,
         line = node.y
      }
   end
end

return util.rule {
   ruleset = 'annoying',
   visitorStrategy = {
      op = checkParentheses
   }
}
