local common = require 'shiroko.common'
local stage = require 'shiroko.stage'
local util = require 'shiroko.util'
local fs = require 'shiroko.fs'

local tl = require 'tl'

local f = string.format

stage.generateStrategy()

local entities = {
   ['<'] = '&lt;',
   ['>'] = '&gt;',
   ['&'] = '&amp;'
}

local function escape(text: string): string
   local escaped = text:gsub('[<>&]', entities)

   return escaped
end

local function colorize(text: string, color: string): string
   if color then
      return f('<span class="%s">%s</span>', color, escape(text))
   else
      return escape(text)
   end
end

local function highlight(
   tokens: {common.Token},
   y1: integer,
   y2: integer,
   x1: integer,
   x2: integer,
   offset: integer
): string
   local out = {}

   local fn: {string: boolean} = {
      ['('] = true,
      ['string'] = true,
      ['{'] = true
   }

   local tokenColors: {string: string} = {
      keyword = 'lightMagenta',
      number = 'yellow',
      integer = 'yellow',
      string = 'lightGreen',
      fnCall = 'blue',
      op = 'cyan',
      invalid = 'red',
      std = 'cyan',
      type = 'lightYellow'
   }

   local invalid = false

   for i = 1, #tokens do
      local token = tokens[i]
      local peek = tokens[i + 1]

      if (token.y + offset) >= y1 and token.x >= x1 then
         invalid = true
      end

      if (token.y + offset) > y2 or ((token.y + offset) == y2 and token.x >= x2) then
         invalid = false
      end

      if invalid and token.tk:sub(0, 1) ~= '$' then
         table.insert(out, colorize(token.tk, 'red'))
      else
         if tokenColors[token.kind] then
            table.insert(out, colorize(token.tk, tokenColors[token.kind]))
         else
            if token.tk:sub(0, 1) ~= '$' then
               if token.kind == 'identifier' and fn[peek.kind] then
                  table.insert(out, colorize(token.tk, tokenColors.fnCall))
               else
                  table.insert(out, escape(token.tk))
               end
            end
         end
      end

      if peek then
         table.insert(out, string.rep('\n', peek.y - token.y))
         table.insert(out, string.rep(' ', peek.x - token.x - #token.tk))
      end
   end

   return table.concat(out)
end

local function main()
   local reports = stage.process(arg[1])

   local filtered = {}

   for i = 1, #reports do
      if reports[i].severity ~= 'style' then
         table.insert(filtered, reports[i])
      end
   end

   local buffer = {}

   for i = 1, #filtered do
      local report = filtered[i]

      table.insert(buffer, colorize(f('[%s] %s', report.code, report.message), 'yellow') .. colorize(f(' - %s:%u:%u\n', report.file, report.line, report.column)))

      if report.fixes then
         for k = 1, #report.fixes do
            local fix = report.fixes[k]

            local contents = fs.read(fix.file)

            local area = table.concat(util.linesBetween(contents, fix.line, fix.lineStop), '\n')

            local highlighted = highlight(
               tl.lex(area) as {common.Token},
               fix.line,
               fix.lineStop,
               fix.column,
               fix.columnStop,
               fix.line - 1
            )

            highlighted =
               colorize('┌─ ', 'green') .. fix.file .. ':' ..
               fix.line .. ':' .. fix.column .. '\n' .. colorize('│ ', 'green') ..
               highlighted:gsub('\n', '\n' .. colorize('│ ', 'green')) .. '\n'

            local highlightedCode = highlight(
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
               buffer,
               highlighted .. colorize('= ', 'green') ..
               (fix.code == '' and 'Delete this code' or 'Replace with `' .. highlightedCode .. '`') ..
               '\n'
            )
         end
      end
   end

   local str = table.concat(buffer)

   local padding = 5
   local fontSize = 4
   local lineSpacing = 1

   local maxLineWidth = util.maxLine(str)

   local width, height = math.floor(maxLineWidth * (fontSize / 4)), padding + util.countChars(str, '\n') * (fontSize + lineSpacing) + padding

   local data = f([[
      <svg viewBox="0 0 %u %u" xmlns="http://www.w3.org/2000/svg">
         <style>
            /* https://github.com/aaron-williamson/base16-alacritty/blob/master/colors/base16-tomorrow-night-256.yml */
            pre {
               background: #222436;
               margin: 0;
               padding: %upx;
               border-radius: 6px;
               color: #c8d3f5;
               font: %upx SFMono-Regular, Consolas, Liberation Mono, Menlo, monospace;
            }

            pre .black   { color: #191a2a; }
            pre .red     { color: #ff5370; }
            pre .green   { color: #a5c477; }
            pre .yellow  { color: #ddac68; }
            pre .blue    { color: #375aba; }
            pre .magenta { color: #e295d2; }
            pre .cyan    { color: #86e1fc; }
            pre .white   { color: #c8d3f5; }

            pre .brightBlack    { color: #222436; }
            pre .brightRed      { color: #ff757f; }
            pre .brightGreen    { color: #c3e88d; }
            pre .brightYellow   { color: #ffc777; }
            pre .brightBlue     { color: #82aaff; }
            pre .brightMagenta  { color: #fca7ea; }
            pre .brightCyan     { color: #9fe6fc; }
            pre .brightWhite    { color: #c8d3f5; }
         </style>
         <foreignObject x="0" y="0" width="%u" height="%u">
            <div xmlns="http://www.w3.org/1999/xhtml">
               <pre>%s</pre>
            </div>
         </foreignObject>
      </svg>
   ]], width, height, padding, fontSize, width, height, str)

   io.write(data)
end

main()
