local record glob
   glob: function(string, integer): {string}
   GLOB_NOSPACE: integer
   GLOB_NOMATCH: integer
   GLOB_NOCHECK: integer
   GLOB_MARK: integer
   GLOB_ABORTED: integer
   GLOB_ERR: integer
end

return glob
