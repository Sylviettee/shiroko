local function isJoined(tk: string): boolean
   return tk == tk:lower() and not tk:find('_', 1, true)
end

local function isSnakeCase(tk: string): boolean
   return tk == tk:lower()
end

local function isScreamingSnakeCase(tk: string): boolean
   return tk == tk:upper()
end

local function isCamelCase(tk: string): boolean
   return tk:sub(0, 1) == tk:sub(0, 1):lower() and not tk:find('_', 1, true)
end

local function isPascalCase(tk: string): boolean
   return tk:sub(0, 1) == tk:sub(0, 1):upper() and not tk:find('_', 1, true)
end

local function detect(tk: string, expecting: string): string
   if tk:sub(0, 1) == '_' then
      tk = tk:sub(2)
   end

   if tk == '' then
      return expecting
   elseif isJoined(tk) then
      return expecting == 'PascalCase' and 'unknown' or expecting or 'unknown'
   elseif isSnakeCase(tk) then
      return 'snake_case'
   elseif isScreamingSnakeCase(tk) then
      return 'SCREAMING_SNAKE_CASE'
   elseif isCamelCase(tk) then
      return 'camelCase'
   elseif isPascalCase(tk) then
      return 'PascalCase'
   else
      return 'unknown'
   end
end

return {
   isSnakeCase = isSnakeCase,
   isCamelCase = isCamelCase,
   isPascalCase = isPascalCase,
   detect = detect
}
