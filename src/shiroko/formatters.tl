local common = require 'shiroko.common'
local color = require 'shiroko.color'
local util = require 'shiroko.util'

local fs = require 'shiroko.fs'
local tl = require 'tl'

local colors: {string: string} = {
   error = color.red,
   warning = color.lightYellow,
   style = color.lightMagenta,
   hint = color.green
}

local function full(reports: {common.Report}): string
   local ret = {}
   local codes: {string: {common.Report}} = {}

   for i = 1, #reports do
      local report = reports[i]

      if codes[report.severity] then
         table.insert(codes[report.severity], report)
      else
         codes[report.severity] = { report }
      end
   end

   for name, section in pairs(codes) do
      local details = {}

      for i = 1, #section do
         local report = section[i]

         local code = '[' .. report.code .. '] '

         table.insert(
            details,
            color.fg(colors[name]) .. code .. report.message .. color.reset ..
            ' ' .. color.fg(color.white) .. '- ' .. report.file .. ':' .. report.line .. ':' .. report.column
         )

         if report.fixes then
            for k = 1, #report.fixes do
               local fix = report.fixes[k]

               local contents = fs.read(fix.file)

               local area = table.concat(util.linesBetween(contents, fix.line, fix.lineStop), '\n')

               local highlighted = color.highlight(
                  tl.lex(area) as {common.Token},
                  fix.line,
                  fix.lineStop,
                  fix.column,
                  fix.columnStop,
                  fix.line - 1
               )

               highlighted =
                  color.fg(color.green) .. '┌─ ' .. color.reset .. fix.file .. ':' ..
                  fix.line .. ':' .. fix.column .. '\n' .. color.fg(color.green) .. '│ ' .. color.reset ..
                  highlighted:gsub('\n', '\n' .. color.fg(color.green) .. '│ ' .. color.reset) .. '\n'

               local highlightedCode = color.highlight(
                  tl.lex(fix.code) as {common.Token},
                  #contents, -- Pro-gamer move
                  #contents,
                  #contents,
                  #contents,
                  0
               )

               if #highlightedCode == 0 then
                  highlightedCode = fix.code
               end

               table.insert(
                  details,
                  highlighted .. color.fg(color.green) .. '= ' .. color.reset ..
                  (fix.code == '' and 'Delete this code' or 'Replace with `' .. highlightedCode .. '`')
               )
            end
         end
      end

      table.insert(ret, table.concat(details, '\n'))
   end

   return table.concat(ret, '\n')
end

local function quiet(reports: {common.Report}): string
   local str = {}

   for i = 1, #reports do
      local report = reports[i]

      table.insert(str,
         report.severity ..
         '[' .. report.code .. ']' .. ' - ' .. report.file ..
         ':' .. report.line .. ':' .. report.column .. ': ' ..
         report.message
      )
   end

   return table.concat(str, '\n')
end

return {
   full = full,
   quiet = quiet
}
