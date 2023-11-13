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
         ['shiroko.rules.quoteStyle'] = 'out/shiroko/rules/quoteStyle.lua',
         ['shiroko.rules.divideByZero'] = 'out/shiroko/rules/divideByZero.lua',
         ['shiroko.visit'] = 'out/shiroko/visit.lua',
         ['shiroko.rules.caseStyle'] = 'out/shiroko/rules/caseStyle.lua',
         ['shiroko.patterns'] = 'out/shiroko/patterns.lua',
         ['shiroko.formatters'] = 'out/shiroko/formatters.lua',
         ['shiroko.util'] = 'out/shiroko/util.lua',
         ['shiroko.rules.adjacentOverloads'] = 'out/shiroko/rules/adjacentOverloads.lua',
         ['shiroko.rules.globalUsage'] = 'out/shiroko/rules/globalUsage.lua',
         ['shiroko.glob'] = 'out/shiroko/glob.lua',
         ['shiroko.cli'] = 'out/shiroko/cli.lua',
         ['shiroko.cases'] = 'out/shiroko/cases.lua',
         ['shiroko.common'] = 'out/shiroko/common.lua',
         ['shiroko.fs'] = 'out/shiroko/fs.lua',
         ['shiroko.report'] = 'out/shiroko/report.lua',
         ['shiroko.color'] = 'out/shiroko/color.lua',
         ['shiroko.rules.invalidPattern'] = 'out/shiroko/rules/invalidPattern.lua',
         ['shiroko.rules.lineFormatting'] = 'out/shiroko/rules/lineFormatting.lua',
         ['shiroko.rules.suspiciousReverseLoop'] = 'out/shiroko/rules/suspiciousReverseLoop.lua',
         ['shiroko.stage'] = 'out/shiroko/stage.lua',
         ['shiroko.rules.parenthesesDropped'] = 'out/shiroko/rules/parenthesesDropped.lua',
         ['shiroko.rules.emptyBlock'] = 'out/shiroko/rules/emptyBlock.lua',
         ['shiroko.rules.ifSameThenElse'] = 'out/shiroko/rules/ifSameThenElse.lua',
         ['shiroko.options'] = 'out/shiroko/options.lua',
   },
   install = {
      lua = {
         ['shiroko.rules.quoteStyle'] = 'src/shiroko/rules/quoteStyle.tl',
         ['shiroko.rules.divideByZero'] = 'src/shiroko/rules/divideByZero.tl',
         ['shiroko.visit'] = 'src/shiroko/visit.tl',
         ['shiroko.rules.caseStyle'] = 'src/shiroko/rules/caseStyle.tl',
         ['shiroko.patterns'] = 'src/shiroko/patterns.tl',
         ['shiroko.formatters'] = 'src/shiroko/formatters.tl',
         ['shiroko.util'] = 'src/shiroko/util.tl',
         ['shiroko.rules.adjacentOverloads'] = 'src/shiroko/rules/adjacentOverloads.tl',
         ['shiroko.rules.globalUsage'] = 'src/shiroko/rules/globalUsage.tl',
         ['shiroko.glob'] = 'src/shiroko/glob.tl',
         ['shiroko.cli'] = 'src/shiroko/cli.tl',
         ['shiroko.cases'] = 'src/shiroko/cases.tl',
         ['shiroko.common'] = 'src/shiroko/common.tl',
         ['shiroko.fs'] = 'src/shiroko/fs.tl',
         ['shiroko.report'] = 'src/shiroko/report.tl',
         ['shiroko.color'] = 'src/shiroko/color.tl',
         ['shiroko.rules.invalidPattern'] = 'src/shiroko/rules/invalidPattern.tl',
         ['shiroko.rules.lineFormatting'] = 'src/shiroko/rules/lineFormatting.tl',
         ['shiroko.rules.suspiciousReverseLoop'] = 'src/shiroko/rules/suspiciousReverseLoop.tl',
         ['shiroko.stage'] = 'src/shiroko/stage.tl',
         ['shiroko.rules.parenthesesDropped'] = 'src/shiroko/rules/parenthesesDropped.tl',
         ['shiroko.rules.emptyBlock'] = 'src/shiroko/rules/emptyBlock.tl',
         ['shiroko.rules.ifSameThenElse'] = 'src/shiroko/rules/ifSameThenElse.tl',
         ['shiroko.options'] = 'src/shiroko/options.tl',
      },
      bin = {
         'bin/shiroko',
      }
   }
}
