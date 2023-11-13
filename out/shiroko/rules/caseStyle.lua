local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local string = _tl_compat and _tl_compat.string or string; local table = _tl_compat and _tl_compat.table or table; local options = require('shiroko.options')
local common = require('shiroko.common')
local cases = require('shiroko.cases')
local util = require('shiroko.util')

local checkedNewTypes = {
   enum = true,
   record = true,
   arrayrecord = true,
}



local function recurseCheckTable(node, vars)


   for _, field in ipairs(node) do
      local name = field.key.conststr

      if name then
         table.insert(vars, { name, field.key.x, field.key.y })
      end

      if field.value.kind == 'table_literal' then
         recurseCheckTable(field.value, vars)
      end
   end
end

local function checkCase(node)
   local vars = {}

   if node.vars then
      local types = node.exps

      for i, var in ipairs(node.vars) do
         table.insert(vars, { var.tk, var.x, var.y, var.is_const })

         if options.checkRecordCase and types and types[i] and types[i].kind == 'table_literal' then
            recurseCheckTable(types[i], vars)
         end
      end
   end

   if node.kind == 'newtype' then
      local def = node.newtype.def



      if checkedNewTypes[def.typename] then
         table.insert(vars, { def.names[1], node.x, node.y, nil, options.objectCaseStyle })

         if options.checkRecordCase and def.typename:find('record', 1, true) then
            if def.field_order then
               for i = 1, #def.field_order do
                  local name = def.field_order[i]

                  local field = def.fields[name]

                  if field.typename ~= 'typetype' and field.typename ~= 'nestedtype' then
                     local x = def.positions and def.positions[name] and def.positions[name][1] or field.x
                     local y = def.positions and def.positions[name] and def.positions[name][2] or field.y

                     if not x or not y then
                        break
                     end

                     table.insert(vars, { name, x, y })
                  end
               end
            end
         end
      end
   end

   local rets = {}

   for i = 1, #vars do
      local var = vars[i]

      local name = var[1]
      local case = var[5] or options.case

      local detected = cases.detect(name, case)

      local column, line, columnStop, lineStop = 
      var[2],
      var[3],
      var[2] + #name,
      var[3] + util.countChars(name, '\n')



      if detected ~= case and not (var[4] and detected == 'SCREAMING_SNAKE_CASE') then
         table.insert(rets, {
            message = 'Expected ' .. case .. ', got ' .. cases.detect(name),
            column = column,
            line = line,
            columnStop = columnStop,
            lineStop = lineStop,
            severity = 'style',
            code = 'caseStyle',
         })
      end

      if name:match('^_+%u[%u%d]*$') then

         table.insert(rets, {
            message = 'Variables shouldn\'t start with `_` and be uppercase',
            column = column,
            line = line,
            columnStop = columnStop,
            lineStop = lineStop,
            severity = 'style',
            code = 'caseStyle',
         })
      end
   end

   return #rets > 0 and util.mark(rets)
end

return util.rule({
   ruleset = 'luarocks-modified',
   visitorStrategy = {
      local_function = checkCase,
      global_function = checkCase,
      record_function = checkCase,

      local_declaration = checkCase,
      global_declaration = checkCase,

      newtype = checkCase,
   },
})
