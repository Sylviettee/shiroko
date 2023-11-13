local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local io = _tl_compat and _tl_compat.io or io; local os = _tl_compat and _tl_compat.os or os; local pairs = _tl_compat and _tl_compat.pairs or pairs; local string = _tl_compat and _tl_compat.string or string; local table = _tl_compat and _tl_compat.table or table
local SHIROKO_VERSION = 'dev'

local formatters = require('shiroko.formatters')
local options = require('shiroko.options')
local common = require('shiroko.common')
local stage = require('shiroko.stage')
local color = require('shiroko.color')
local util = require('shiroko.util')
local glob = require('shiroko.glob')
local fs = require('shiroko.fs')
local json = require('dkjson')
local tl = require('tl')

local parser = require('argparse')('shiroko', 'The experimental Teal linter')

parser:command_target('command')
parser:command('check-all')

parser:command('check'):
argument('file'):
convert(fs.exists):
args('+')

parser:flag('-q --quiet', 'Disable all unneeded output. This is the same as `--display-style=quiet`')

parser:flag('-v --version', 'The version of shiroko')

parser:option('--color', 'If color should be enabled or not'):
choices({ 'enabled', 'disabled' })

parser:option('--display-style', 'The output display style'):
choices({ 'quiet', 'full', 'json' }):
default('full')

parser:option('--rules', 'The location of the rules file'):
default('shiroko.lua')

















local function panic(msg)
   io.stderr:write(msg .. '\n')
   os.exit(-1)
end

local tlLex = tl.lex

local function turbo(on)


   if on then
      if jit then
         jit.off();

         (tl).lex = function(input)
            jit.on()
            local r1, r2 = tlLex(input)
            jit.off()
            return r1, r2
         end
      end

      collectgarbage('stop')
   else
      if jit then
         jit.on()
         tl.lex = tlLex
      end

      collectgarbage('restart')
   end
end

local function setupEnv(config)
   config._init_env_modules = config._init_env_modules or {}

   if config.global_env_def then
      table.insert(config._init_env_modules, 1, config.global_env_def)
   end

   local env, err = tl.init_env(false, false, '5.3', config._init_env_modules)

   if not env then
      panic(err)
   end

   return env
end

local function check(config, included, formatter)
   local modules = {}



   if config.include_dir then
      for i = 1, #config.include_dir do
         local path = config.include_dir[i]

         fs.dirTree(path, modules)
      end
   end

   local search = util.mockSearch(modules)

   tl.search_module = search

   local env = setupEnv(config)

   local reports = {}

   turbo(true)

   for i = 1, #included do
      local file = included[i]

      local rets = stage.process(file, env)

      util.tblMerge(reports, rets)
   end

   turbo(false)

   local fail = false
   local cleaned = {}

   for i = 1, #reports do
      local report = reports[i]
      local contents = fs.read(report.file)

      local ignores = util.handleIgnore(util.fetchLine(contents, report.line))

      if not ignores[report.code] then
         table.insert(cleaned, report)

         fail = true
      end
   end

   if formatter == 'json' then
      io.write(json.encode(cleaned))
   else
      local res = formatter(cleaned)

      io.write(res .. (#res > 0 and '\n' or ''))
   end

   os.exit(fail and -1 or 0)
end

local function wholeProject(config, formatter)
   local sourceDir = config.source_dir or ''

   if sourceDir:sub(#sourceDir, #sourceDir) ~= '/' and sourceDir ~= '' then
      sourceDir = sourceDir .. '/'
   end

   local included = {}

   if sourceDir ~= '' then
      fs.searchAll(sourceDir, '%.tl', included)
   end

   do
      local globed = {}

      if config.include then
         for i = 1, #config.include do
            local files = glob(included, sourceDir .. config.include[i])

            for k = 1, #files do
               globed[files[k]] = true
            end
         end
      end

      if config.files then
         for i = 1, #config.files do
            globed[config.files[i]] = true
         end
      end

      if config.exclude then
         for i = 1, #config.exclude do
            local files = glob(included, sourceDir .. config.exclude[i])

            for k = 1, #files do
               globed[files[k]] = nil
            end
         end
      end

      for file in pairs(globed) do
         table.insert(included, file)
      end
   end

   check(config, included, formatter)
end

local function single(files, config, formatter)
   check(config, files, formatter)
end

local function main()
   local args = parser:parse()

   if args.version then
      io.write(SHIROKO_VERSION .. '\n')
      return
   end

   if args.color == 'disabled' then
      color.disable()
   end

   local formatter

   if args.display_style == 'full' and not args.quiet then
      formatter = formatters.full
   elseif args.display_style == 'quiet' or args.quiet then
      formatter = formatters.quiet
   else
      formatter = 'json'
   end

   local rules = {}

   if args.rules and fs.exists(args.rules) then
      rules = util.require(args.rules) or {}
   end

   for i, v in pairs(rules) do
      if (options)[i] then
         (options)[i] = v
      end
   end

   local lints = rules.lints

   if type(lints) == "table" then
      for i = 1, #lints do
         table.insert(stage.rules, lints[i])
      end
   end

   local config = {}

   if fs.exists('tlconfig.lua') then
      config = util.require('tlconfig.lua')
   end

   stage.generateStrategy()

   if args.command == 'check-all' then
      wholeProject(config, formatter)
   elseif args.command == 'check' then
      single(args.file, config, formatter)
   end
end

return main
