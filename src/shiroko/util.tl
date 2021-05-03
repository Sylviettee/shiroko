local common = require 'shiroko.common'
local fs = require 'shiroko.fs'

local tl = require 'tl'

local util = {
   _requireCache = {} as {string: any},
   _lineCache = {} as {string: {string}},
   _uidCount = 0
}

function util.quote(str: string): common.Node
   local tokens = tl.lex(str)

   local _, node = tl.parse_program(tokens)

   return node as common.Node
end

function util.typeid(str: string, env: tl.Env): integer
   local res = tl.process_string('return ' .. str, false, env)

   return res.type.typeid
end

function util.load(str: string, env: table): any, any
   local fn: function

   if _VERSION == 'Lua 5.1' then
      global loadstring: function(string, string): function
      global setfenv: function(function, table)

      fn = assert(loadstring(str, 'util.load'))

      setfenv(fn, env)
   else
      fn = assert(load(str, 'util.load', 'bt', env))
   end

   local res, err = pcall(fn)

   return res, err
end

-- Mostly for typechecking
-- I guess it can also do a light-wrap
function util.rule(base: common.Rule): common.Rule
   base.docs = base.docs or ''

   return base
end

function util.require(path: string): any
   if util._requireCache[path] then
      return util._requireCache[path]
   end

   local data = fs.read(path)

   local fn: function

   if _VERSION == 'Lua 5.1' then
      global loadstring: function(string, string): function
      fn = assert(loadstring(data, path))
   else
      fn = assert(load(data, path))
   end

   local res = fn()

   util._requireCache[path] = res

   return res
end

function util.shallowCopy<T>(tbl: T): T
   local newTbl: T = {} as T

   for i, v in pairs(tbl as {string: any}) do
      (newTbl as {string: any})[i] = v
   end

   return newTbl
end

function util.reverse<T>(tbl: {T}): {T}
   local reversed = {}

   for i = #tbl, 1, -1 do
      table.insert(reversed, tbl[i])
   end

   return reversed
end

function util.flatten<T>(tbl: {{T} | T}): {T}
   local new = {}

   for i = 1, #tbl do
      if type(tbl[i]) == 'table' then
         for sub = 1, (#tbl[i] as {T}) do
            table.insert(new, (tbl[i] as {T})[sub])
         end
      else
         table.insert(new, tbl[i] as T)
      end
   end

   return new
end

--; TODO This should really preserve type information as we don't really care about the compiled output
function util.stringify(node: common.Node, opts: {string: boolean}): string
   return (tl.pretty_print_ast as function(common.Node, {string: boolean}): string)(node, opts or {
      preserve_indent = false,
      preserve_newlines = false
   })
end

function util.walkLines<T>(str: string, fn: function(string, integer): T): {T}
   if util._lineCache[str] then
      local rets = {}

      for i = 1, #util._lineCache[str] do
         local ret = fn(util._lineCache[str][i], i)

         if ret then
            table.insert(rets, ret)
         end
      end

      return rets
   end

   local pos = 1
   local line = 1
   local rets = {}

   util._lineCache[str] = {}

   while true do
      local nextNewline = str:find('\n', pos, true)
      local toBreak: boolean

      if not nextNewline then
         toBreak = true
         nextNewline = #str
      end

      local lineContents = str:sub(nextNewline, nextNewline) == '\n' and str:sub(pos, nextNewline - 1) or
         str:sub(pos, nextNewline)

      local ret = fn(lineContents, line)

      table.insert(util._lineCache[str], lineContents)

      if ret then
         table.insert(rets, ret)
      end

      pos = nextNewline + 1
      line = line + 1

      if toBreak then
         break
      end
   end

   return rets
end

function util.fetchLine(str: string, expectingLine: integer): string
   if util._lineCache[str] then
      return util._lineCache[str][expectingLine]
   end

   return util.walkLines(str, function(line: string, lineNum: integer): string
      if expectingLine == lineNum then
         return line
      end
   end)[1]
end

function util.linesBetween(str: string, start: integer, stop: integer): {string}
   local lines = {}

   for i = start, stop do
      table.insert(lines, util.fetchLine(str, i))
   end

   return lines
end

function util.countChars(str: string, char: string): integer
   local count = 0

   while true do
      local nextChar = str:find(char, 1, true)

      if nextChar then
         count = count + 1
         str = str:sub(nextChar + 1)
      else
         break
      end
   end

   return count
end

function util.maxLine(str: string): integer
   local max = 0

   util.walkLines(str, function(line: string): nil
      if #line > max then
         max = #line
      end
   end)

   return max
end

function util.merge<T, V>(...: function(T): V): function(T): {V}
   local args = {...}

   return function(data: T): {V}
      local rets = {
         _multi = true
      } as {V}

      for i = 1, #args do
         local ret = args[i](data)

         if ret then
            table.insert(rets, ret)
         end
      end

      return rets
   end
end

function util.tblMerge<T>(tbl1: {T}, tbl2: {T})
   if table.move then
      table.move(tbl2, 1, #tbl2, #tbl1 + 1, tbl1)
      return
   end

   for i = 1, #tbl2 do
      table.insert(tbl1, tbl2[i])
   end
end

function util.capitalize(str: string): string
   return str:sub(0, 1):upper() .. str:sub(2)
end

function util.rpad(str: string, len: integer): string
   return string.rep(' ', len - #str) .. str
end

function util.split(str: string, sep: string): {string}
   local ret = {}

   for part in str:gmatch('([^' .. sep .. ']+)') do
      table.insert(ret, part)
   end

   return ret
end

function util.trim(str: string): string
   return str:match('^%s*(.-)%s*$')
end

function util.union(str: string, expect: string): boolean -- shiroko: allow(booleanReturnPrefix)
   local allowed = {}

   local rest = str

   while rest ~= '' do
      local nextType = str:find('|', 1, true)

      if not nextType then
         allowed[rest] = true
         break
      else
         allowed[rest:sub(0, nextType - 1)] = true
         rest = rest:sub(nextType + 1)
      end
   end

   return allowed[expect]
end

function util.mark<T>(arr: {T}): {T}
   (arr as {string: boolean})._multi = true

   return arr
end

function util.isArray<T>(arr: T): boolean
   return (arr as table)._multi == true
end

function util.mockSearch(modules: {string: string}): function(string, boolean): string, FILE, {string}
   local oldSearch = tl.search_module

   return function(module: string, dtl: boolean): string, FILE, {string}
      if modules[module] then
         local fileName = modules[module]

         return fileName, assert(io.open(fileName, 'r'))
      else
         return oldSearch(module, dtl)
      end
   end
end

function util.handleIgnore(line: string): {string: boolean}
   if not line then
      return {}
   end

   local codes = {}

   local comment = line:match('%-%- ?shiroko: ?allow%((.-)%)$')

   if not comment then
      return {}
   end

   local raw = util.split(comment, ',')

   for i = 1, #raw do
      codes[util.trim(raw[i])] = true
   end

   return codes as {string: boolean}
end

return util
