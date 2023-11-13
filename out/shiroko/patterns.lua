local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local string = _tl_compat and _tl_compat.string or string; local table = _tl_compat and _tl_compat.table or table


local formatters = {
   ['%'] = '',

   ['d'] = 'integer',
   ['i'] = 'integer',
   ['o'] = 'integer',
   ['x'] = 'integer',
   ['X'] = 'integer',
   ['u'] = 'integer',
   ['c'] = 'integer',
   ['f'] = 'number|integer',
   ['e'] = 'number|integer',
   ['E'] = 'number|integer',
   ['g'] = 'number|integer',
   ['G'] = 'number|integer',
   ['a'] = 'number|integer',
   ['A'] = 'number|integer',
   ['s'] = 'string|number|integer',
   ['q'] = 'string|number|integer|boolean|nil',
}

local function validateFormat(str)
   local errs = {}
   local types = {}

   local rest = str


   while true do
      local percent = rest:find('%', 1, true)

      if not percent then
         break
      end

      local captureIndex = rest:sub(percent + 1, percent + 1)

      if not formatters[captureIndex] then
         local msg = 
         captureIndex == '' and
         'malformed pattern (ends with \'%\')' or
         'invalid format string %' .. captureIndex

         table.insert(errs, msg)
      else
         local tp = formatters[captureIndex]

         if tp ~= '' then
            table.insert(types, tp)
         end
      end

      rest = rest:sub(percent + 2)
   end

   return #errs == 0 and types or nil, #errs > 0 and errs
end

return {
   validateFormat = validateFormat,
}
