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
local s = require"complementree.defaults"

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

The defaults are:
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
- `wrap`: triggers the completion using this matches function.

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

## Filtering and sorting results

There are two special types of combinators: filters and comparators.

They simply change the order and filter the completion results, and
there are quite a bunch of them.

### Filters

- `preffix`: only keep suggestions that start with the current written
  word
- `strict_preffix`: same as `preffix` but be a strict preffix
  (different thant written word)
- `amount(n)`: only take the first `n` suggestions

### Comparators

- `alphabetic`: sort results alphabetically
- `length`: sort results by length
If you have `romgrk/fzy-lua-native` installed, there will also be:
- `fzy`: sort based on the fuzzy score (case sensitive)
- `ifzy`: case insensitive version

## Utilities

A threading-macro-like function in also provided for convenience,
which looks line `combinators.pipeline(source, ...)` and just applies
all combinators in the `...` one by one.

## Examples

Fuzzy LSP:
```lua
combinators.pipeline(sources.lsp_matches, comparators.fzy, filters.amount(6))
```

Fuzzy LSP and LuaSnip only if lsp returns something:
```lua
combinators.pipeline(combinators.optional(source.lsp_matches, source.luasnip_matches), comparators.fzy, filters.amount(6))
```

Look in the [defaults file](./lua/complementree/defaults.lua) for
more.
