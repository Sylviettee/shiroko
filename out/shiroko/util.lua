local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local assert = _tl_compat and _tl_compat.assert or assert; local io = _tl_compat and _tl_compat.io or io; local load = _tl_compat and _tl_compat.load or load; local pairs = _tl_compat and _tl_compat.pairs or pairs; local pcall = _tl_compat and _tl_compat.pcall or pcall; local string = _tl_compat and _tl_compat.string or string; local table = _tl_compat and _tl_compat.table or table; local common = require('shiroko.common')
local fs = require('shiroko.fs')

local tl = require('tl')

local util = {
   _requireCache = {},
   _lineCache = {},
   _uidCount = 0,
}

function util.quote(str)
   local tokens = tl.lex(str)

   local _, node = tl.parse_program(tokens)

   return node
end

function util.typeid(str, env)
   local res = tl.process_string('return ' .. str, false, env)

   return res.type.typeid
end

function util.load(str, env)
   local fn

   if _VERSION == 'Lua 5.1' then



      fn = assert(loadstring(str, 'util.load'))

      setfenv(fn, env)
   else
      fn = assert(load(str, 'util.load', 'bt', env))
   end

   local res, err = pcall(fn)

   return res, err
end



function util.rule(base)
   base.docs = base.docs or ''

   return base
end

function util.require(path)
   if util._requireCache[path] then
      return util._requireCache[path]
   end

   local data = fs.read(path)

   local fn

   if _VERSION == 'Lua 5.1' then

      fn = assert(loadstring(data, path))
   else
      fn = assert(load(data, path))
   end

   local res = fn()

   util._requireCache[path] = res

   return res
end

function util.shallowCopy(tbl)
   local newTbl = {}

   for i, v in pairs(tbl) do
      (newTbl)[i] = v
   end

   return newTbl
end

function util.reverse(tbl)
   local reversed = {}

   for i = #tbl, 1, -1 do
      table.insert(reversed, tbl[i])
   end

   return reversed
end

function util.flatten(tbl)
   local new = {}

   for i = 1, #tbl do
      if type(tbl[i]) == 'table' then
         for sub = 1, (#tbl[i]) do
            table.insert(new, (tbl[i])[sub])
         end
      else
         table.insert(new, tbl[i])
      end
   end

   return new
end


function util.stringify(node, opts)
   return (tl.pretty_print_ast)(node, opts or {
      preserve_indent = false,
      preserve_newlines = false,
   })
end

function util.walkLines(str, fn)
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
      local toBreak

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

function util.fetchLine(str, expectingLine)
   if util._lineCache[str] then
      return util._lineCache[str][expectingLine]
   end

   return util.walkLines(str, function(line, lineNum)
      if expectingLine == lineNum then
         return line
      end
   end)[1]
end

function util.linesBetween(str, start, stop)
   local lines = {}

   for i = start, stop do
      table.insert(lines, util.fetchLine(str, i))
   end

   return lines
end

function util.countChars(str, char)
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

function util.maxLine(str)
   local max = 0

   util.walkLines(str, function(line)
      if #line > max then
         max = #line
      end
   end)

   return max
end

function util.merge(...)
   local args = { ... }

   return function(data)
      local rets = {
         _multi = true,
      }

      for i = 1, #args do
         local ret = args[i](data)

         if ret then
            table.insert(rets, ret)
         end
      end

      return rets
   end
end

function util.tblMerge(tbl1, tbl2)
   if table.move then
      table.move(tbl2, 1, #tbl2, #tbl1 + 1, tbl1)
      return
   end

   for i = 1, #tbl2 do
      table.insert(tbl1, tbl2[i])
   end
end

function util.capitalize(str)
   return str:sub(0, 1):upper() .. str:sub(2)
end

function util.rpad(str, len)
   return string.rep(' ', len - #str) .. str
end

function util.split(str, sep)
   local ret = {}

   for part in str:gmatch('([^' .. sep .. ']+)') do
      table.insert(ret, part)
   end

   return ret
end

function util.trim(str)
   return str:match('^%s*(.-)%s*$')
end

function util.union(str, expect)
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

function util.mark(arr)
   (arr)._multi = true

   return arr
end

function util.isArray(arr)
   return (arr)._multi == true
end

function util.mockSearch(modules)
   local oldSearch = tl.search_module

   return function(module, dtl)
      if modules[module] then
         local fileName = modules[module]

         return fileName, assert(io.open(fileName, 'r'))
      else
         return oldSearch(module, dtl)
      end
   end
end

function util.handleIgnore(line)
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

   return codes
end

return util
