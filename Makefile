test:
	nvim --headless -c "luafile tests/combinators.lua" -c "quit"
	@echo ""
