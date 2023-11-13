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
   ['op']: function(Node, Node, etc): any
   ['nil']: function(Node, Node, etc): any
   ['string']: function(Node, Node, etc): any
   ['number']: function(Node, Node, etc): any
   ['integer']: function(Node, Node, etc): any
   ['boolean']: function(Node, Node, etc): any
   ['table_literal']: function(Node, Node, etc): any
   ['table_item']: function(Node, Node, etc): any
   ['function']: function(Node, Node, etc): any
   ['expression_list']: function(Node, Node, etc): any
   ['enum_item']: function(Node, Node, etc): any
   ['if']: function(Node, Node, etc): any
   ['if_block']: function(Node, Node, etc): any
   ['while']: function(Node, Node, etc): any
   ['fornum']: function(Node, Node, etc): any
   ['forin']: function(Node, Node, etc): any
   ['goto']: function(Node, Node, etc): any
   ['label']: function(Node, Node, etc): any
   ['repeat']: function(Node, Node, etc): any
   ['do']: function(Node, Node, etc): any
   ['break']: function(Node, Node, etc): any
   ['return']: function(Node, Node, etc): any
   ['newtype']: function(Node, Node, etc): any
   ['argument']: function(Node, Node, etc): any
   ['type_identifier']: function(Node, Node, etc): any
   ['variable']: function(Node, Node, etc): any
   ['variable_list']: function(Node, Node, etc): any
   ['statements']: function(Node, Node, etc): any
   ['assignment']: function(Node, Node, etc): any
   ['argument_list']: function(Node, Node, etc): any
   ['local_function']: function(Node, Node, etc): any
   ['global_function']: function(Node, Node, etc): any
   ['local_type']: function(Node, Node, etc): any
   ['global_type']: function(Node, Node, etc): any
   ['record_function']: function(Node, Node, etc): any
   ['local_declaration']: function(Node, Node, etc): any
   ['global_declaration']: function(Node, Node, etc): any
   ['identifier']: function(Node, Node, etc): any
   ['cast']: function(Node, Node, etc): any
   ['...']: function(Node, Node, etc): any
   ['paren']: function(Node, Node, etc): any
   ['error_node']: function(Node, Node, etc): any
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
