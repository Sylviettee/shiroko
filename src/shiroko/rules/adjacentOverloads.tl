local common = require 'shiroko.common'
local util = require 'shiroko.util'

local function _reportCheckAdjacentOverloads(x: integer, y: integer): common.Report
   return {
      message = 'Overloads should be adjacent to each other',
      code = 'adjacentOverloads',
      severity = 'style',
      column = x,
      line = y
   }
end

local function checkAdjacentOverloads(node: common.Node): {common.Report}
   local byOrder = {}
   local rets: {common.Report} = {}

   local def = node.newtype.def

   if def.typename ~= 'record' and def.typename ~= 'arrayrecord' then
      return
   end

   for i = 1, #def.field_order do
      local name = def.field_order[i]
      local field = def.fields[name]

      if field.types then
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

return util.rule {
   ruleset = 'luarocks-modified',
   visitorStrategy = {
      newtype = checkAdjacentOverloads
   }
}
