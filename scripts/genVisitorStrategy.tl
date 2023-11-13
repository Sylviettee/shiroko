local kinds = {
   'op',
   'nil',
   'string',
   'number',
   'integer',
   'boolean',
   'table_literal',
   'table_item',
   'function',
   'expression_list',
   'enum_item',
   'if',
   'if_block',
   'while',
   'fornum',
   'forin',
   'goto',
   'label',
   'repeat',
   'do',
   'break',
   'return',
   'newtype',
   'argument',
   'type_identifier',
   'variable',
   'variable_list',
   'statements',
   'assignment',
   'argument_list',
   'local_function',
   'global_function',
   'local_type',
   'global_type',
   'record_function',
   'local_declaration',
   'global_declaration',
   'identifier',
   'cast',
   '...',
   'paren',
   'error_node'
}

local base = [[
local record VisitorStrategy
%s
end
]]

local list = {}

for i = 1, #kinds do
   local kind = kinds[i]

   -- no support for Report | {Report} yet
   table.insert(list, '   [\'' .. kind .. '\']: function(Node, Node, etc): any' )
end

print(string.format(base, table.concat(list, '\n')))
