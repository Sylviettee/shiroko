package.path = './out/?/init.lua;./out/?.lua;' .. package.path

local baseSpec = [[
rockspec_format = '3.0'
package = 'shiroko'
version = 'dev-1'
source = {
   url = 'git+https://github.com/sovietkitsune/shiroko.git'
}
dependencies = {
   'argparse',
   'luafilesystem',
   'tl',
   'dkjson'
}
build = {
   type = 'builtin',
   modules = {
%s
   },
   install = {
      lua = {
%s
      },
      bin = {
         'bin/shiroko',
      }
   }
}
]]

local fs = require 'shiroko.fs'

local tree = fs.dirTree('src/')

local modules = {}
local install = {}

for i, v in pairs(tree) do
   table.insert(install, '         [\'' .. i .. '\'] = \'' .. v .. '\',')
   table.insert(modules, '         [\'' .. i .. '\'] = \'' .. v:gsub('^src/', 'out/'):gsub('%.tl$', '.lua') .. '\',')
end

print(baseSpec:format(table.concat(modules, '\n'), table.concat(install, '\n')))
