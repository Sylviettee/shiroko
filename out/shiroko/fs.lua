local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local assert = _tl_compat and _tl_compat.assert or assert; local debug = _tl_compat and _tl_compat.debug or debug; local io = _tl_compat and _tl_compat.io or io; local string = _tl_compat and _tl_compat.string or string; local table = _tl_compat and _tl_compat.table or table; local lfs = require('lfs')


local fs = {

   _location = nil,
   _cache = {},
}

function fs.scriptLocation()
   if fs._location then
      return fs._location
   end

   fs._location = debug.getinfo(2, 'S').source:sub(2):match('(.*/)')

   return fs._location
end

function fs.type(path)
   return lfs.attributes(path).mode
end

function fs.read(path)
   assert(path, 'Expected a file!')
   if fs._cache[path] then
      return fs._cache[path]
   end

   local f = assert(io.open(path, 'rb'))

   local data = f:read('*a')

   f:close()

   fs._cache[path] = data

   return data
end

function fs.write(path, data)
   fs._cache[path] = path

   local f = assert(io.open(path, 'w'))

   f:write(data)

   f:close()
end

function fs.exists(path)
   local exists = lfs.attributes(path)

   if exists then
      return path
   else
      return nil, path .. ': No such file or directory'
   end
end

function fs.dirTree(dir, current, depth)
   local tree = current or {}

   depth = (depth or '') .. (dir:match('.*/(.*)$') or dir)

   if depth ~= '' then
      depth = depth .. '.'
   end

   depth = depth:match('%.*(.*)')

   local pLen = #dir

   if dir:sub(pLen, pLen) == '/' then
      dir = dir:sub(0, pLen - 1)
   end

   if fs.exists(dir) then
      for path in lfs.dir(dir) do
         if path ~= '.' and path ~= '..' then
            local attributes = lfs.attributes(dir .. '/' .. path)

            if attributes.mode == 'file' and (path:match('%.lua$') or path:match('%.tl$')) then
               tree[depth .. path:match('(.-)%.(.*)')] = dir .. '/' .. path
            elseif attributes.mode == 'directory' then
               fs.dirTree(dir .. '/' .. path, tree, depth)
            end
         end
      end
   end

   return tree
end

function fs.search(pat, dirs)
   for i = 1, #dirs do
      if lfs.attributes(dirs[i]) and lfs.attributes(dirs[i]).mode == 'directory' then
         for path in lfs.dir(dirs[i]) do
            if path:match(pat) then
               return path
            end
         end
      end
   end
end

function fs.searchAll(path, pat, current)
   current = current or {}

   local pLen = #path

   if path:sub(pLen, pLen) == '/' then
      path = path:sub(0, pLen - 1)
   end

   for location in lfs.dir(path) do
      if location ~= '.' and location ~= '..' then
         if lfs.attributes(path .. '/' .. location).mode == 'directory' then
            fs.searchAll(path .. '/' .. location, pat, current)
         elseif lfs.attributes(path .. '/' .. location).mode == 'file' and location:match(pat) then
            table.insert(current, path .. '/' .. location)
         end
      end
   end

   return current
end

function fs.mkdir(path)
   lfs.mkdir(path)
end

function fs.copy(file, newLocation, map)
   if map then
      fs.write(newLocation, map(fs.read(file)))
   else
      fs.write(newLocation, fs.read(file))
   end
end

function fs.copyDir(path, newPath, map)
   fs.mkdir(newPath)

   for location in lfs.dir(path) do
      if location ~= '.' and location ~= '..' then
         if lfs.attributes(path .. '/' .. location).mode == 'directory' then
            fs.copyDir(path .. '/' .. location, newPath .. '/' .. location)
         elseif lfs.attributes(path .. '/' .. location).mode == 'file' then
            fs.copy(path .. '/' .. location, newPath .. '/' .. location, map)
         end
      end
   end
end

return fs
