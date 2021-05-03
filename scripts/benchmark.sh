#!/usr/bin/env bash

if [ ! -f benchmark/tl.lua ]; then
   echo "Cloning \`tl.lua\`"

   git clone https://github.com/teal-language/tl

   cp tl/tl.lua benchmark/tl.lua

   echo "Cleaning up"

   rm -rf tl
fi

benchmark() {
   hyperfine -i --warmup 5 "selene $1 --display-style quiet" "bin/d-shiroko check $1 -q" "luacheck $1 -q"
}

benchmark 'benchmark/tl.lua'
benchmark 'benchmark/startup.lua'
