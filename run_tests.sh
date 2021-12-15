#!/bin/sh

rm -f /tmp/res

find tests/ -name "*.lua" | while read file
do
  echo "$file"
  nvim -u min.vim --headless -c "luafile $file" -c "quit" 2>&1 | tee -a /tmp/res
  echo ""
done
if ! grep -q "^not ok" /tmp/res
then
  exit 0
else
  exit 1
fi
