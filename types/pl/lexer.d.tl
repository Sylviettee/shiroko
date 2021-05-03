-- More debugging tools

local record lexer
   type token = {string, string}
   type tokenaction = function(string, {string: any}): (string, string)
   type tokendesc = {string, lexer.tokenaction}
   type tokenstream = function(any): (string, string)

   scan: function(
       string | FILE,
       {tokendesc, tokenaction},
       {string: boolean},
       {string: any}
   ): tokenstream
   lua: function(
       string | FILE,
       {string: boolean},
       {string: any}
   ): tokenstream
   cpp: function(
       string | FILE,
       {string: boolean},
       {string: any}
   ): tokenstream

   insert: function(lexer.tokenstream, string, string)
   insert: function(lexer.tokenstream, {lexer.token} | lexer.tokenstream)

   getline: function(lexer.tokenstream): string
   getrest: function(lexer.tokenstream): string
   lineno: function(lexer.tokenstream): number, number
   get_keywords: function(): {string: boolean}

   get_separated_list: function(
       lexer.tokenstream,
       string,
       string
   ): {{lexer.token}}, lexer.token

   skipws: function(lexer.tokenstream): lexer.token
   expecting: function(
       lexer.tokenstream,
       string,
       boolean
   ): lexer.token
end

return lexer
