lint:
	stylua -c .

test:
	nvim -u min.vim --headless -c "luafile tests/combinators.lua" -c "quit"
	@echo ""
