local common = require 'shiroko.common'
local util = require 'shiroko.util'

local Node = common.Node -- shiroko: allow(caseStyle)

-- Smaller `recurse_node` with no sort of types since you shouldn't need it
local function visit<T, V>(
   root: Node,
   visitor: {string: {function(Node, Node, V): T}},
   extra: V,
   all: function(Node): T
): {T}
   if not root then
      return
   end

   local recurse: function(Node, Node)

   local function walkChildren(ast: Node)
      for _, child in ipairs(ast) do
         recurse(child, ast)
      end
   end

   local function walkVarsExpr(ast: Node)
      recurse(ast.vars, ast)

      if ast.exps then
         recurse(ast.exps, ast)
      end
   end

   local function walkVarValue(ast: Node)
      recurse(ast.var, ast)
      recurse(ast.value, ast)
   end

   local function walkNamedFunction(ast: Node)
      recurse(ast.name, ast)
      recurse(ast.args, ast)
      recurse(ast.body, ast)
   end

   local walkers: {string: function(Node)} = {
      op = function(ast: Node)
         recurse(ast.e1, ast)

         if ast.op.arity == 2 and ast.op.op ~= 'is' and ast.op.op ~= 'as' then
            recurse(ast.e2, ast)
         end
      end,
      statements = walkChildren,
      argument_list = walkChildren,
      table_literal = walkChildren,
      variable_list = walkChildren,
      expression_list = walkChildren,
      newtype = walkChildren,

      table_item = function(ast: Node)
         recurse(ast.key, ast)
         recurse(ast.value, ast)
      end,

      assignment = walkVarsExpr,
      local_declaration = walkVarsExpr,
      global_declaration = walkVarsExpr,

      local_type = walkVarValue,
      global_type = walkVarValue,

      ['if'] = function(ast: Node)
         for _, e in ipairs(ast.if_blocks) do
            recurse(e, ast)
         end
      end,

      if_block = function(ast: Node)
         if ast.exp then
            recurse(ast.exp, ast)
         end

         recurse(ast.body, ast)
      end,

      ['while'] = function(ast: Node)
         recurse(ast.exp, ast)
         recurse(ast.body, ast)
      end,

      ['repeat'] = function(ast: Node)
         recurse(ast.body, ast)
         recurse(ast.exp, ast)
      end,

      ['function'] = function(ast: Node)
         recurse(ast.args, ast)
         recurse(ast.body, ast)
      end,

      local_function = walkNamedFunction,
      global_function = walkNamedFunction,
      record_function = function(ast: Node)
         recurse(ast.fn_owner, ast)
         recurse(ast.name, ast)
         recurse(ast.args, ast)
         recurse(ast.body, ast)
      end,

      forin = function(ast: Node)
         recurse(ast.vars, ast)
         recurse(ast.exps, ast)
         recurse(ast.body, ast)
      end,

      fornum = function(ast: Node)
         recurse(ast.var, ast)
         recurse(ast.from, ast)
         recurse(ast.to, ast)
         if ast.step then
            recurse(ast.step, ast)
         end
         recurse(ast.body, ast)
      end,

      ['return'] = function(ast: Node)
         recurse(ast.exps, ast)
      end,

      ['do'] = function(ast: Node)
         recurse(ast.body, ast)
      end,

      paren = function(ast: Node)
         recurse(ast.e1, ast)
      end,
   }

   local rets = {}

   local function handleRet(ret: T)
      if util.isArray(ret) and ret is {T} then
         for i = 1, #ret do
            table.insert(rets, ret[i])
         end
      else
         table.insert(rets, ret)
      end
   end

   recurse = function(ast: Node, parent: Node)
      local kind = assert(ast.kind)

      local cbs = visitor[kind]

      if cbs then
         for i = 1, #cbs do
            local ret = cbs[i](ast, parent, extra)

            if ret then
               handleRet(ret)
            end
         end
      end

      if all then
         local ret = all(ast)

         if ret then
            handleRet(ret)
         end
      end

      local fn = walkers[kind]

      if fn then
         fn(ast)
      end
   end

   recurse(root)

   return rets
end

return visit
