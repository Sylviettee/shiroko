local tl = require 'tl'

local enum TypeName
   'typetype'
   'nestedtype'
   'typevar'
   'typearg'
   'function'
   'array'
   'map'
   'tupletable'
   'arrayrecord'
   'record'
   'enum'
   'boolean'
   'string'
   'nil'
   'thread'
   'number'
   'integer'
   'union'
   'nominal'
   'bad_nominal'
   'emptytable'
   'table_item'
   'unresolved_emptytable_value'
   'tuple'
   'poly' -- intersection types, currently restricted to polymorphic functions defined inside records
   'any'
   'unknown' -- to be used in lax mode only
   'invalid' -- producing a new value of this type (not propagating) must always produce a type error
   'unresolved'
   'none'
end

local record Type
   {Type}
   y: integer
   x: integer
   filename: string
   typename: TypeName
   tk: string

   yend: integer
   xend: integer

   -- Lua compatibility
   needs_compat: boolean

   -- tuple
   is_va: boolean

   -- poly, union, tupletable
   types: {Type}

   -- typetype
   def: Type
   is_alias: boolean
   closed: boolean

   -- map
   keys: Type
   values: Type

   -- records
   typeargs: {Type}
   fields: {string: Type}
   field_order: {string}
   meta_fields: {string: Type}
   meta_field_order: {string}
   positions: {string: {integer, integer}}
   is_userdata: boolean

   -- array
   elements: Type
   -- tupletable/array
   inferred_len: integer

   -- function
   is_method: boolean
   args: Type
   arg_names: {string}
   rets: Type

   typeid: integer

   -- nominal
   names: {string}
   typevals: Type
   found: Type    -- type is found but typeargs are not resolved
   resolved: Type -- type is found and typeargs are resolved

   -- typevar
   typevar: string

   -- typearg
   typearg: string

   -- table items
   kname: string
   ktype: Type
   vtype: Type

   -- emptytable
   declared_at: Node
   assigned_to: string
   keys_inferred_at: Node
   keys_inferred_at_file: string
   inferred_at: Node
   inferred_at_file: string
   emptytable_type: Type

   -- enum
   enumset: {string:boolean}

   -- unresolved items
   labels: {string:{Node}}
   nominals: {string:{Type}}
end

local enum NodeKind
   'op'
   'nil'
   'string'
   'number'
   'integer'
   'boolean'
   'table_literal'
   'table_item'
   'function'
   'expression_list'
   'enum_item'
   'if'
   'if_block'
   'while'
   'fornum'
   'forin'
   'goto'
   'label'
   'repeat'
   'do'
   'break'
   'return'
   'newtype'
   'argument'
   'type_identifier'
   'variable'
   'variable_list'
   'statements'
   'assignment'
   'argument_list'
   'local_function'
   'global_function'
   'local_type'
   'global_type'
   'record_function'
   'local_declaration'
   'global_declaration'
   'identifier'
   'cast'
   '...'
   'paren'
   'error_node'
end

local enum FactType
   'is'     -- type-based type judgement (its negation implies the subtracted type)
   '=='     -- value-based type judgement (its negation does not imply a subtracted type negated)
   'not'    -- negation: type-based judgements subtract, value-based judgements prove nothing
   'and'    -- conjunction: type-based judgements intersect, any value-based judgement downgrades all
   'or'     -- disjunction: type-based judgements unite, any value-based judgement downgrades all
   'truthy' -- expression that is either truthy or a runtime error
end

local record Fact
   fact: FactType
   where: Node

   -- is
   var: string
   typ: Type

   -- not, and, or
   f1: Fact
   f2: Fact

   metamethod __call: function(Fact, Fact): Fact
end

local record Operator
   y: integer
   x: integer
   arity: integer
   op: string
   prec: integer
end

local enum KeyParsed
   'short'
   'long'
   'implicit'
end

local record Node
   {Node}

   record ExpectedContext
      kind: NodeKind
      name: string
   end

   y: integer
   x: integer
   tk: string
   kind: NodeKind
   symbol_list_slot: integer
   semicolon: boolean

   is_longstring: boolean

   yend: integer
   xend: integer

   known: Fact

   -- bidirectional inference
   expected: Type
   expected_context: Node.ExpectedContext

   key: Node
   value: Node
   key_parsed: KeyParsed

   typeargs: Type
   args: Node
   rets: Type
   body: Node

   name: Node

   -- statements list in a `repeat`, delay closing scope
   is_repeat: boolean

   -- local
   is_const: boolean

   fn_owner: Node
   is_method: boolean

   exp: Node
   if_parent: Node
   if_block_n: integer
   if_blocks: {Node}

   -- fornum
   var: Node
   from: Node
   to: Node
   step: Node

   -- forin
   vars: Node
   exps: Node

   -- newtype
   newtype: Type
   is_alias: boolean

   -- expressions
   op: Operator
   e1: Node
   e2: Node
   constnum: number
   conststr: string
   failstore: boolean

   -- table literal
   array_len: integer

   -- goto
   label: string

   casttype: Type

   type: Type
   decltype: Type
end

local enum TokenKind
   'keyword'
   'op'
   'string'
   '[' ']' '(' ')' '{' '}' ',' ':' '#' '`' '.' ';'
   '::'
   '...'
   'identifier'
   'number'
   'integer'
   '$invalid_string$'
   '$invalid_number$'
   '$invalid$'
   '$EOF$'
end

local record Token
   x: integer
   y: integer
   i: integer
   tk: string
   kind: TokenKind
end

local enum Severity
   'hint'
   'error'
   'warning'
   'style'
end

local record Fix
   line: integer
   lineStop: integer
   column: integer
   columnStop: integer
   code: string
   experimental: boolean
   file: string
end

local record Report
   message: string
   file: string
   line: integer
   lineStop: integer
   column: integer
   columnStop: integer
   severity: Severity
   code: string
   fixes: {Fix}
end

-- Cannot discriminate a union... lies
local type etc = {tl.Env, string}

-- scripts/genVisitorStrategy.tl
local record VisitorStrategy
   ['op']: function(Node, Node, etc): Report
   ['op']: function(Node, Node): Report
   ['op']: function(Node): Report
   ['op']: function(Node, Node, etc): {Report}
   ['op']: function(Node, Node): {Report}
   ['op']: function(Node): {Report}
   ['nil']: function(Node, Node, etc): Report
   ['nil']: function(Node, Node): Report
   ['nil']: function(Node): Report
   ['nil']: function(Node, Node, etc): {Report}
   ['nil']: function(Node, Node): {Report}
   ['nil']: function(Node): {Report}
   ['string']: function(Node, Node, etc): Report
   ['string']: function(Node, Node): Report
   ['string']: function(Node): Report
   ['string']: function(Node, Node, etc): {Report}
   ['string']: function(Node, Node): {Report}
   ['string']: function(Node): {Report}
   ['number']: function(Node, Node, etc): Report
   ['number']: function(Node, Node): Report
   ['number']: function(Node): Report
   ['number']: function(Node, Node, etc): {Report}
   ['number']: function(Node, Node): {Report}
   ['number']: function(Node): {Report}
   ['integer']: function(Node, Node, etc): Report
   ['integer']: function(Node, Node): Report
   ['integer']: function(Node): Report
   ['integer']: function(Node, Node, etc): {Report}
   ['integer']: function(Node, Node): {Report}
   ['integer']: function(Node): {Report}
   ['boolean']: function(Node, Node, etc): Report
   ['boolean']: function(Node, Node): Report
   ['boolean']: function(Node): Report
   ['boolean']: function(Node, Node, etc): {Report}
   ['boolean']: function(Node, Node): {Report}
   ['boolean']: function(Node): {Report}
   ['table_literal']: function(Node, Node, etc): Report
   ['table_literal']: function(Node, Node): Report
   ['table_literal']: function(Node): Report
   ['table_literal']: function(Node, Node, etc): {Report}
   ['table_literal']: function(Node, Node): {Report}
   ['table_literal']: function(Node): {Report}
   ['table_item']: function(Node, Node, etc): Report
   ['table_item']: function(Node, Node): Report
   ['table_item']: function(Node): Report
   ['table_item']: function(Node, Node, etc): {Report}
   ['table_item']: function(Node, Node): {Report}
   ['table_item']: function(Node): {Report}
   ['function']: function(Node, Node, etc): Report
   ['function']: function(Node, Node): Report
   ['function']: function(Node): Report
   ['function']: function(Node, Node, etc): {Report}
   ['function']: function(Node, Node): {Report}
   ['function']: function(Node): {Report}
   ['expression_list']: function(Node, Node, etc): Report
   ['expression_list']: function(Node, Node): Report
   ['expression_list']: function(Node): Report
   ['expression_list']: function(Node, Node, etc): {Report}
   ['expression_list']: function(Node, Node): {Report}
   ['expression_list']: function(Node): {Report}
   ['enum_item']: function(Node, Node, etc): Report
   ['enum_item']: function(Node, Node): Report
   ['enum_item']: function(Node): Report
   ['enum_item']: function(Node, Node, etc): {Report}
   ['enum_item']: function(Node, Node): {Report}
   ['enum_item']: function(Node): {Report}
   ['if']: function(Node, Node, etc): Report
   ['if']: function(Node, Node): Report
   ['if']: function(Node): Report
   ['if']: function(Node, Node, etc): {Report}
   ['if']: function(Node, Node): {Report}
   ['if']: function(Node): {Report}
   ['if_block']: function(Node, Node, etc): Report
   ['if_block']: function(Node, Node): Report
   ['if_block']: function(Node): Report
   ['if_block']: function(Node, Node, etc): {Report}
   ['if_block']: function(Node, Node): {Report}
   ['if_block']: function(Node): {Report}
   ['while']: function(Node, Node, etc): Report
   ['while']: function(Node, Node): Report
   ['while']: function(Node): Report
   ['while']: function(Node, Node, etc): {Report}
   ['while']: function(Node, Node): {Report}
   ['while']: function(Node): {Report}
   ['fornum']: function(Node, Node, etc): Report
   ['fornum']: function(Node, Node): Report
   ['fornum']: function(Node): Report
   ['fornum']: function(Node, Node, etc): {Report}
   ['fornum']: function(Node, Node): {Report}
   ['fornum']: function(Node): {Report}
   ['forin']: function(Node, Node, etc): Report
   ['forin']: function(Node, Node): Report
   ['forin']: function(Node): Report
   ['forin']: function(Node, Node, etc): {Report}
   ['forin']: function(Node, Node): {Report}
   ['forin']: function(Node): {Report}
   ['goto']: function(Node, Node, etc): Report
   ['goto']: function(Node, Node): Report
   ['goto']: function(Node): Report
   ['goto']: function(Node, Node, etc): {Report}
   ['goto']: function(Node, Node): {Report}
   ['goto']: function(Node): {Report}
   ['label']: function(Node, Node, etc): Report
   ['label']: function(Node, Node): Report
   ['label']: function(Node): Report
   ['label']: function(Node, Node, etc): {Report}
   ['label']: function(Node, Node): {Report}
   ['label']: function(Node): {Report}
   ['repeat']: function(Node, Node, etc): Report
   ['repeat']: function(Node, Node): Report
   ['repeat']: function(Node): Report
   ['repeat']: function(Node, Node, etc): {Report}
   ['repeat']: function(Node, Node): {Report}
   ['repeat']: function(Node): {Report}
   ['do']: function(Node, Node, etc): Report
   ['do']: function(Node, Node): Report
   ['do']: function(Node): Report
   ['do']: function(Node, Node, etc): {Report}
   ['do']: function(Node, Node): {Report}
   ['do']: function(Node): {Report}
   ['break']: function(Node, Node, etc): Report
   ['break']: function(Node, Node): Report
   ['break']: function(Node): Report
   ['break']: function(Node, Node, etc): {Report}
   ['break']: function(Node, Node): {Report}
   ['break']: function(Node): {Report}
   ['return']: function(Node, Node, etc): Report
   ['return']: function(Node, Node): Report
   ['return']: function(Node): Report
   ['return']: function(Node, Node, etc): {Report}
   ['return']: function(Node, Node): {Report}
   ['return']: function(Node): {Report}
   ['newtype']: function(Node, Node, etc): Report
   ['newtype']: function(Node, Node): Report
   ['newtype']: function(Node): Report
   ['newtype']: function(Node, Node, etc): {Report}
   ['newtype']: function(Node, Node): {Report}
   ['newtype']: function(Node): {Report}
   ['argument']: function(Node, Node, etc): Report
   ['argument']: function(Node, Node): Report
   ['argument']: function(Node): Report
   ['argument']: function(Node, Node, etc): {Report}
   ['argument']: function(Node, Node): {Report}
   ['argument']: function(Node): {Report}
   ['type_identifier']: function(Node, Node, etc): Report
   ['type_identifier']: function(Node, Node): Report
   ['type_identifier']: function(Node): Report
   ['type_identifier']: function(Node, Node, etc): {Report}
   ['type_identifier']: function(Node, Node): {Report}
   ['type_identifier']: function(Node): {Report}
   ['variable']: function(Node, Node, etc): Report
   ['variable']: function(Node, Node): Report
   ['variable']: function(Node): Report
   ['variable']: function(Node, Node, etc): {Report}
   ['variable']: function(Node, Node): {Report}
   ['variable']: function(Node): {Report}
   ['variable_list']: function(Node, Node, etc): Report
   ['variable_list']: function(Node, Node): Report
   ['variable_list']: function(Node): Report
   ['variable_list']: function(Node, Node, etc): {Report}
   ['variable_list']: function(Node, Node): {Report}
   ['variable_list']: function(Node): {Report}
   ['statements']: function(Node, Node, etc): Report
   ['statements']: function(Node, Node): Report
   ['statements']: function(Node): Report
   ['statements']: function(Node, Node, etc): {Report}
   ['statements']: function(Node, Node): {Report}
   ['statements']: function(Node): {Report}
   ['assignment']: function(Node, Node, etc): Report
   ['assignment']: function(Node, Node): Report
   ['assignment']: function(Node): Report
   ['assignment']: function(Node, Node, etc): {Report}
   ['assignment']: function(Node, Node): {Report}
   ['assignment']: function(Node): {Report}
   ['argument_list']: function(Node, Node, etc): Report
   ['argument_list']: function(Node, Node): Report
   ['argument_list']: function(Node): Report
   ['argument_list']: function(Node, Node, etc): {Report}
   ['argument_list']: function(Node, Node): {Report}
   ['argument_list']: function(Node): {Report}
   ['local_function']: function(Node, Node, etc): Report
   ['local_function']: function(Node, Node): Report
   ['local_function']: function(Node): Report
   ['local_function']: function(Node, Node, etc): {Report}
   ['local_function']: function(Node, Node): {Report}
   ['local_function']: function(Node): {Report}
   ['global_function']: function(Node, Node, etc): Report
   ['global_function']: function(Node, Node): Report
   ['global_function']: function(Node): Report
   ['global_function']: function(Node, Node, etc): {Report}
   ['global_function']: function(Node, Node): {Report}
   ['global_function']: function(Node): {Report}
   ['local_type']: function(Node, Node, etc): Report
   ['local_type']: function(Node, Node): Report
   ['local_type']: function(Node): Report
   ['local_type']: function(Node, Node, etc): {Report}
   ['local_type']: function(Node, Node): {Report}
   ['local_type']: function(Node): {Report}
   ['global_type']: function(Node, Node, etc): Report
   ['global_type']: function(Node, Node): Report
   ['global_type']: function(Node): Report
   ['global_type']: function(Node, Node, etc): {Report}
   ['global_type']: function(Node, Node): {Report}
   ['global_type']: function(Node): {Report}
   ['record_function']: function(Node, Node, etc): Report
   ['record_function']: function(Node, Node): Report
   ['record_function']: function(Node): Report
   ['record_function']: function(Node, Node, etc): {Report}
   ['record_function']: function(Node, Node): {Report}
   ['record_function']: function(Node): {Report}
   ['local_declaration']: function(Node, Node, etc): Report
   ['local_declaration']: function(Node, Node): Report
   ['local_declaration']: function(Node): Report
   ['local_declaration']: function(Node, Node, etc): {Report}
   ['local_declaration']: function(Node, Node): {Report}
   ['local_declaration']: function(Node): {Report}
   ['global_declaration']: function(Node, Node, etc): Report
   ['global_declaration']: function(Node, Node): Report
   ['global_declaration']: function(Node): Report
   ['global_declaration']: function(Node, Node, etc): {Report}
   ['global_declaration']: function(Node, Node): {Report}
   ['global_declaration']: function(Node): {Report}
   ['identifier']: function(Node, Node, etc): Report
   ['identifier']: function(Node, Node): Report
   ['identifier']: function(Node): Report
   ['identifier']: function(Node, Node, etc): {Report}
   ['identifier']: function(Node, Node): {Report}
   ['identifier']: function(Node): {Report}
   ['cast']: function(Node, Node, etc): Report
   ['cast']: function(Node, Node): Report
   ['cast']: function(Node): Report
   ['cast']: function(Node, Node, etc): {Report}
   ['cast']: function(Node, Node): {Report}
   ['cast']: function(Node): {Report}
   ['...']: function(Node, Node, etc): Report
   ['...']: function(Node, Node): Report
   ['...']: function(Node): Report
   ['...']: function(Node, Node, etc): {Report}
   ['...']: function(Node, Node): {Report}
   ['...']: function(Node): {Report}
   ['paren']: function(Node, Node, etc): Report
   ['paren']: function(Node, Node): Report
   ['paren']: function(Node): Report
   ['paren']: function(Node, Node, etc): {Report}
   ['paren']: function(Node, Node): {Report}
   ['paren']: function(Node): {Report}
   ['error_node']: function(Node, Node, etc): Report
   ['error_node']: function(Node, Node): Report
   ['error_node']: function(Node): Report
   ['error_node']: function(Node, Node, etc): {Report}
   ['error_node']: function(Node, Node): {Report}
   ['error_node']: function(Node): {Report}
end

local record Rule
   severity: Severity
   ruleset: string
   code: string
   docs: string

   visitorStrategy: VisitorStrategy
   lintProgram: function(Node, string): {Report}
end

return {
   Node = Node,
   Type = Type,
   Token = Token,
   Severity = Severity,
   Report = Report,
   Fix = Fix,
   Rule = Rule,
   VisitorStrategy = VisitorStrategy,
   etc = etc
}
