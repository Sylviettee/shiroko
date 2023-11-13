local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local assert = _tl_compat and _tl_compat.assert or assert; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local table = _tl_compat and _tl_compat.table or table; local common = require('shiroko.common')
local util = require('shiroko.util')

local Node = common.Node


local function visit(
   root,
   visitor,
   extra,
   all)

   if not root then
      return
   end

   local recurse

   local function walkChildren(ast)
      for _, child in ipairs(ast) do
         recurse(child, ast)
      end
   end

   local function walkVarsExpr(ast)
      recurse(ast.vars, ast)

      if ast.exps then
         recurse(ast.exps, ast)
      end
   end

   local function walkVarValue(ast)
      recurse(ast.var, ast)
      recurse(ast.value, ast)
   end

   local function walkNamedFunction(ast)
      recurse(ast.name, ast)
      recurse(ast.args, ast)
      recurse(ast.body, ast)
   end

   local walkers = {
      op = function(ast)
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

      table_item = function(ast)
         recurse(ast.key, ast)
         recurse(ast.value, ast)
      end,

      assignment = walkVarsExpr,
      local_declaration = walkVarsExpr,
      global_declaration = walkVarsExpr,

      local_type = walkVarValue,
      global_type = walkVarValue,

      ['if'] = function(ast)
         for _, e in ipairs(ast.if_blocks) do
            recurse(e, ast)
         end
      end,

      if_block = function(ast)
         if ast.exp then
            recurse(ast.exp, ast)
         end

         recurse(ast.body, ast)
      end,

      ['while'] = function(ast)
         recurse(ast.exp, ast)
         recurse(ast.body, ast)
      end,

      ['repeat'] = function(ast)
         recurse(ast.body, ast)
         recurse(ast.exp, ast)
      end,

      ['function'] = function(ast)
         recurse(ast.args, ast)
         recurse(ast.body, ast)
      end,

      local_function = walkNamedFunction,
      global_function = walkNamedFunction,
      record_function = function(ast)
         recurse(ast.fn_owner, ast)
         recurse(ast.name, ast)
         recurse(ast.args, ast)
         recurse(ast.body, ast)
      end,

      forin = function(ast)
         recurse(ast.vars, ast)
         recurse(ast.exps, ast)
         recurse(ast.body, ast)
      end,

      fornum = function(ast)
         recurse(ast.var, ast)
         recurse(ast.from, ast)
         recurse(ast.to, ast)
         if ast.step then
            recurse(ast.step, ast)
         end
         recurse(ast.body, ast)
      end,

      ['return'] = function(ast)
         recurse(ast.exps, ast)
      end,

      ['do'] = function(ast)
         recurse(ast.body, ast)
      end,

      paren = function(ast)
         recurse(ast.e1, ast)
      end,
   }

   local rets = {}

   local function handleRet(ret)
      if util.isArray(ret) and type(ret) == "table" then
         for i = 1, #ret do
            table.insert(rets, ret[i])
         end
      else
         table.insert(rets, ret)
      end
   end

   recurse = function(ast, parent)
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
