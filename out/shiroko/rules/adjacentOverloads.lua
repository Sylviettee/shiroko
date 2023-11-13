local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local table = _tl_compat and _tl_compat.table or table; local common = require('shiroko.common')
local util = require('shiroko.util')

local function _reportCheckAdjacentOverloads(x, y)
   return {
      message = 'Overloads should be adjacent to each other',
      code = 'adjacentOverloads',
      severity = 'style',
      column = x,
      line = y,
   }
end

local function checkAdjacentOverloads(node)
   local byOrder = {}
   local rets = {}

   local def = node.newtype.def

   if def.typename ~= 'record' and def.typename ~= 'arrayrecord' then
      return
   end

   for i = 1, #def.field_order do
      local name = def.field_order[i]
      local field = def.fields[name]

      if field.types and field.types[1].y and field.types[#field.types].y then
         for y = field.types[1].y, field.types[#field.types].y do
            if byOrder[y] then
               table.insert(rets, _reportCheckAdjacentOverloads(field.x, y))
            else
               byOrder[y] = true
            end
         end
      else
         local yPos = field.y or def.positions and def.positions[name][2]

         if byOrder[yPos] then
            table.insert(rets, _reportCheckAdjacentOverloads(field.x, yPos))
         elseif yPos then
            byOrder[yPos] = true
         end
      end
   end

   return #rets > 0 and util.mark(rets)
end

return util.rule({
   ruleset = 'luarocks-modified',
   visitorStrategy = {
      newtype = checkAdjacentOverloads,
   },
})
