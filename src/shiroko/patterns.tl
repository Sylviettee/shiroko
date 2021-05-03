--; TODO - string patterns (that sounds chaotic)
--; TODO - `%5d` is a valid format (5 spaces before the number :notLikeThis:)

local formatters: {string: string} = {
   ['%'] = '',

   ['d'] = 'integer',
   ['i'] = 'integer',
   ['o'] = 'integer',
   ['x'] = 'integer',
   ['X'] = 'integer', -- shiroko: allow(caseStyle)
   ['u'] = 'integer',
   ['c'] = 'integer',
   ['f'] = 'number|integer',
   ['e'] = 'number|integer',
   ['E'] = 'number|integer', -- shiroko: allow(caseStyle)
   ['g'] = 'number|integer',
   ['G'] = 'number|integer', -- shiroko: allow(caseStyle)
   ['a'] = 'number|integer',
   ['A'] = 'number|integer', -- shiroko: allow(caseStyle)
   ['s'] = 'string|number|integer',
   ['q'] = 'string|number|integer|boolean|nil',
}

local function validateFormat(str: string): {string}, {string}
   local errs = {}
   local types = {}

   local rest = str

   -- First pass: Magic characters
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
   validateFormat = validateFormat
}
