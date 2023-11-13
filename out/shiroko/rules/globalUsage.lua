local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local common = require('shiroko.common')
local util = require('shiroko.util')

local ignore = {
   setfenv = true,
   getfenv = true,
   unpack = true,
   loadstring = true,
   jit = true,
}

local function checkGlobal(node, parent)
   local allowIgnore = true

   if node.vars then
      for _, var in ipairs(node.vars) do
         if not ignore[var.tk] then
            allowIgnore = false
            break
         end
      end
   elseif node.name and not ignore[node.name.tk] then
      allowIgnore = false
   else
      allowIgnore = ignore[node.var.tk]
   end

   if allowIgnore then
      return
   end

   return {
      message = 'Global usage is not allowed',
      severity = 'warning',
      code = 'globalUsage',
      column = parent.x or node.x,
      line = node.y,
      columnStop = node.xend or node.x,
      lineStop = node.yend or node.y,
   }
end

return util.rule({
   ruleset = 'recommended',
   visitorStrategy = {
      global_declaration = checkGlobal,
      global_function = checkGlobal,
      global_type = checkGlobal,
   },
})
