lint:
	stylua -c **/*.lua

test:
	nvim --headless -c "luafile tests/combinators.lua" -c "quit"
	@echo ""
