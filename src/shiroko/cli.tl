-- The only const that will be used
local SHIROKO_VERSION <const> = 'dev' -- shiroko: allow(caseStyle)

local formatters = require 'shiroko.formatters'
local options = require 'shiroko.options'
local common = require 'shiroko.common'
local stage = require 'shiroko.stage'
local color = require 'shiroko.color'
local util = require 'shiroko.util'
local glob = require 'shiroko.glob'
local fs = require 'shiroko.fs'
local json = require 'dkjson'
local tl = require 'tl'

local parser = require('argparse')('shiroko', 'The experimental Teal linter')

parser:command_target('command')
parser:command('check-all')

parser:command('check')
   :argument('file')
      :convert(fs.exists)
      :args('+')

parser:flag('-q --quiet', 'Disable all unneeded output. This is the same as `--display-style=quiet`')

parser:flag('-v --version', 'The version of shiroko')

parser:option('--color', 'If color should be enabled or not')
   :choices({'enabled', 'disabled'})

parser:option('--display-style', 'The output display style')
   :choices({'quiet', 'full', 'json'})
   :default('full')

parser:option('--rules', 'The location of the rules file')
   :default('shiroko.lua')

-- The options we actually need
local record TlConfig
   exclude: {string}
   gen_compat: tl.CompatMode
   gen_target: tl.TargetMode
   include_dir: {string}
   include: {string}
   source_dir: string
   files: {string}
   global_env_def: string

   _init_env_modules: {string}
end

local type Formatter = function({common.Report}): string

local function panic(msg: string)
   io.stderr:write(msg .. '\n')
   os.exit(-1)
end

local tlLex = tl.lex

local function turbo(on: boolean) -- Taken from `tl` cli tool
   global jit: {string: function}

   if on then
      if jit then
         jit.off();

         (tl as {string: function}).lex = function(input: string): any...
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

local function setupEnv(config: TlConfig): tl.Env
   config._init_env_modules = config._init_env_modules or {}

   if config.global_env_def then
      table.insert(config._init_env_modules, 1, config.global_env_def)
   end

   local env, err = tl.init_env(false, false, '5.3', config._init_env_modules) as (tl.Env, string)

   if not env then
      panic(err)
   end

   return env
end

global p: function

local function check(config: TlConfig, included: {string}, formatter: Formatter)
   local modules: {string: string} = {}

   -- Doing it ahead should save us time since less lookups?
   -- I'll just lean into watch to save time (like Cyans incremental builds)
   if config.include_dir then
      for i = 1, #config.include_dir do
         local path = config.include_dir[i]

         fs.dirTree(path, modules)
      end
   end

   local search = util.mockSearch(modules)

   tl.search_module = search

   local env = setupEnv(config)

   local reports: {common.Report} = {}

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

   if formatter == 'json' as Formatter then
      io.write(json.encode(cleaned))
   else
      local res = formatter(cleaned)

      io.write(res .. (#res > 0 and '\n' or ''))
   end

   os.exit(fail and -1 or 0)
end

local function wholeProject(config: TlConfig, formatter: Formatter)
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

local function single(files: {string}, config: TlConfig, formatter: Formatter)
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

   local formatter: Formatter

   if args.display_style == 'full' and not args.quiet then
      formatter = formatters.full
   elseif args.display_style == 'quiet' or args.quiet as boolean then
      formatter = formatters.quiet
   else
      formatter = 'json' as Formatter
   end

   local rules: {string: any} = {}

   if args.rules and fs.exists(args.rules as string) then
      rules = util.require(args.rules as string) as {string: any} or {}
   end

   for i, v in pairs(rules as {string: any}) do
      if (options as {string: any})[i] then
         (options as {string: any})[i] = v
      end
   end

   local lints = rules.lints

   if lints is {common.Rule} then -- can only use `is` on variables...
      for i = 1, #lints do
         table.insert(stage.rules, lints[i])
      end
   end

   local config: TlConfig = {}

   if fs.exists('tlconfig.lua') then
      config = util.require('tlconfig.lua') as TlConfig
   end

   stage.generateStrategy()

   if args.command == 'check-all' then
      wholeProject(config, formatter)
   elseif args.command == 'check' then
      single(args.file as {string}, config, formatter)
   end
end

return main
