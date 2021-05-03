local options = require 'shiroko.options'
local common = require 'shiroko.common'
local cases = require 'shiroko.cases'
local util = require 'shiroko.util'

local checkedNewTypes: {string: boolean} = {
   enum = true,
   record = true,
   arrayrecord = true
}

-- Can't let the other pass deal with it since checking tables would break using 3rd-party functions
-- Sure records somewhat also do that but that should be in a `.d.tl` file which isn't checked
local function recurseCheckTable(node: common.Node, vars: {{string, integer, integer, boolean, string}})
   -- p(node)

   for _, field in ipairs(node) do
      local name = field.key.conststr

      if name then
         table.insert(vars, {name, field.key.x, field.key.y})
      end

      if field.value.kind == 'table_literal' then
         recurseCheckTable(field.value, vars)
      end
   end
end

local function checkCase(node: common.Node): {common.Report}
   local vars: {{string, integer, integer, boolean, string}} = {}

   if node.vars then
      local types = node.exps

      for i, var in ipairs(node.vars) do
         table.insert(vars, {var.tk, var.x, var.y, var.is_const})

         if options.checkRecordCase and types and types[i] and types[i].kind == 'table_literal' then
            recurseCheckTable(types[i], vars)
         end
      end
   end

   if node.kind == 'newtype' then
      local def = node.newtype.def

      --p(def)

      if checkedNewTypes[def.typename] then
         table.insert(vars, {def.names[1], node.x, node.y, nil, options.objectCaseStyle})

         if options.checkRecordCase and def.typename:find('record', 1, true) then -- only records have fields
            if def.field_order then
               for i = 1, #def.field_order do
                  local name = def.field_order[i]

                  local field = def.fields[name]

                  if field.typename ~= 'typetype' and field.typename ~= 'nestedtype' then -- Next pass
                     local x = def.positions and def.positions[name] and def.positions[name][1] or field.x
                     local y = def.positions and def.positions[name] and def.positions[name][2] or field.y

                     if not x or not y then
                        break
                     end

                     table.insert(vars, {name, x, y})
                  end
               end
            end
         end
      end
   end

   local rets: {common.Report} = {}

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
      -- ^ ['this key\
      -- extends multiple lines']

      if detected ~= case and not (var[4] and detected == 'SCREAMING_SNAKE_CASE') then
         table.insert(rets, {
            message = 'Expected ' .. case .. ', got ' .. cases.detect(name),
            column = column,
            line = line,
            columnStop = columnStop,
            lineStop = lineStop,
            severity = 'style',
            code = 'caseStyle'
         })
      end

      if name:match('^_+%u[%u%d]*$') then
         -- _VERSION, _G, etc
         table.insert(rets, {
            message = 'Variables shouldn\'t start with `_` and be uppercase',
            column = column,
            line = line,
            columnStop = columnStop,
            lineStop = lineStop,
            severity = 'style',
            code = 'caseStyle'
         })
      end
   end

   return #rets > 0 and util.mark(rets)
end

return util.rule {
   ruleset = 'luarocks-modified',
   visitorStrategy = {
      local_function = checkCase,
      global_function = checkCase,
      record_function = checkCase,

      local_declaration = checkCase,
      global_declaration = checkCase,

      newtype = checkCase
   }
}
