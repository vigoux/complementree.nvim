#!/bin/sh

nvim -u min.vim --headless -c "luafile tests/combinators.lua" -c "quit" 2>&1 | tee /tmp/res
echo ""
if ! grep -q "^not ok" /tmp/res
then
  exit 0
else
  exit 1
fi
