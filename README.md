# Complementree.nvim: a tree-sitter powered completion framework

This plugin is a _completion framework_ built for neovim, and powered
by tree-sitter.

## Installation

This plugin does not have any dependency, but `LuaSnip` is
recommended.

```lua
use {'vigoux/complementree.nvim', requires = {'L3MON4D3/LuaSnip', 'nvim-treesitter/nvim-treesitter'} }
```

## Setting up

`complementree.nvim` works using functions that are called based on
the syntax tree of the file. An example configuration is the
following:

```lua
local comp = require"complementree"
local s = require"complementree.sources"

local lsp_completion = {
  default = s.lsp,
  string = s.ins_completion "C-F",
  comment = s.dummy
}

comp.setup {
  default = s.ins_completion "C-N",
  vim = s.ins_completion "C-V",
  c = lsp_completion,
  lua = lsp_completion,
  rust = lsp_completion
}
```

We define a set of `sources` that are triggered when calling the
`complementree.complete()` function.

The default sources are:
- `lsp`: lsp-only source, with LSP snippets enabled
- `luasnip`: luasnip snippets
- `dummy`: nothing
- `ins_completion`: trigger a `<C-X><C-*>` completion

## Combining sources

You can combine the matches of sources using things called
_combinators_.

There is a few combinators already existing, that take a _matches_
function as input:

- `combine`: just concatenates the results of multiple matches
  functions, returns a _matches_ function
- `non_empty_preffix`: checks that the preffix is non-empty before
  triggering completion
- `optional`: takes two _matches_ functions, and triggers the second
  one only if the first one returns at least one result
- `wrap`: triggers the completion using this matches function. You can
  see usages in the [sources file](./lua/complementree/sources.lua).

The currently implemented matches functions are:
- `lsp_matches`: for lsp-only matches
- `luasnip_matches`: for LuaSnip matches.

Using combinators, you can complete using LSP + LuaSnip with the
following:

```lua
local s = require"complementree.sources"
local cc = require"complementree.combinators"

lsp_and_luasnip = cc.combine(s.luasnip_matches, s.lsp_matches)
```
