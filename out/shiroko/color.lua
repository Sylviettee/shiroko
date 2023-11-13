local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local string = _tl_compat and _tl_compat.string or string; local table = _tl_compat and _tl_compat.table or table; local common = require('shiroko.common')

local f = string.format






local colors = {
   black = '0',
   red = '1',
   green = '2',
   yellow = '3',
   blue = '4',
   magenta = '5',
   cyan = '6',
   white = '7',
   lightBlack = '8',
   lightRed = '9',
   lightGreen = '10',
   lightYellow = '11',
   lightBlue = '12',
   lightMagenta = '13',
   lightCyan = '14',
   lightWhite = '15',
   resetFg = '\27[39m',
   resetBg = '\27[49m',
   reset = '\27[0m',
   disabled = false,
}

function colors.disable(b)
   if b then
      colors.disabled = false
      colors.resetFg = '\27[39m'
      colors.resetBg = '\27[49m'
      colors.reset = '\27[0m'
   else
      colors.disabled = true
      colors.resetFg = ''
      colors.resetBg = ''
      colors.reset = ''
   end
end

function colors.csi(s)
   return colors.disabled and '' or '\27[' .. s
end

function colors.bg(code)
   if colors.disabled then
      return ''
   end

   local sec = type(code) == 'table' and (code).sec or 5
   local color = type(code) == 'table' and (code).color or code

   return colors.csi(f('48;%u;%sm', sec, color))
end

function colors.fg(code)
   if colors.disabled then
      return ''
   end

   local sec = type(code) == 'table' and (code).sec or 5
   local color = type(code) == 'table' and (code).color or code

   return colors.csi(f('38;%u;%sm', sec, color))
end

function colors.truecolor(r, g, b)
   return {
      sec = 2,
      color = f('%u;%u;%u', r, g, b),
   }
end

local tokenColors = {
   keyword = colors.lightMagenta,
   number = colors.yellow,
   integer = colors.yellow,
   string = colors.lightGreen,
   fnCall = colors.blue,
   op = colors.cyan,
   invalid = colors.red,
   std = colors.cyan,
   type = colors.lightYellow,
}


function colors.highlight(
   tokens,
   y1,
   y2,
   x1,
   x2,
   offset)

   local out = {}

   local fn = {
      ['('] = true,
      ['string'] = true,
      ['{'] = true,
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
         table.insert(out, colors.fg(tokenColors.invalid) .. token.tk .. colors.resetFg)
      else
         if tokenColors[token.kind] then
            table.insert(out, colors.fg(tokenColors[token.kind]) .. token.tk .. colors.resetFg)
         else
            if token.tk:sub(0, 1) ~= '$' then
               if token.kind == 'identifier' and fn[peek.kind] then
                  table.insert(out, colors.fg(tokenColors.fnCall) .. token.tk .. colors.resetFg)
               else
                  table.insert(out, token.tk)
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

return colors
