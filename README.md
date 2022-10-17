# __This plugin has moved to [sr.ht](https://sr.ht/~vigoux/complementree.nvim/) and development will continue there__

# Complementree.nvim: a tree-sitter powered completion framework

A tree-sitter powered _completion framework_ built for Neovim,
configured with functions.

Features and design goals:
- Synchronous
- Configured using functions
- Syntax-aware completion
- No autocompletion

## Installation

```lua
use {'https://git.sr.ht/~vigoux/complementree.nvim', requires = {'L3MON4D3/LuaSnip', 'nvim-treesitter/nvim-treesitter'} }
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
- `treesitter`: all names defined in the current file (very basic for now)
- `lsp`: lsp-only source, with LSP snippets enabled
- `luasnip`: luasnip snippets
- `ctags`: tagfile elements, a more configurable form of `<C-X><C-]>`
- `filepath`: paths under the current directory
- `dummy`: nothing
- `ins_completion`: trigger a `<C-X><C-*>` completion

After calling the `setup` function, you can trigger completion by
calling `complementree.complete()`.

## Combining sources

You can combine the matches of sources using things called
_combinators_.

There is a few combinators already existing, that take a _matches_
function as input:

- `combine`: just concatenates the results of multiple matches
  functions, returns a _matches_ function
- `chain`: mimics mucomplete chaining, returns the first non-empty
  matches of the provided functions
- `non_empty_prefix`: checks that the prefix is non-empty before
  triggering completion
- `optional`: takes two _matches_ functions, and triggers the second
  one only if the first one returns at least one result
- `wrap`: triggers the completion using this matches function.

The currently implemented matches functions are:
- `lsp_matches`: for lsp-only matches
- `luasnip_matches`: for LuaSnip matches.
- `filepath_matches`: for files under the current directory
- `ctags_matches`: for matches in the current tagfile
- `treesitter_matches`: for symbols defined in the current file (basic for now)

All the `_matches` function take a table of options as parameters, dig
into the [sources file](./teal/complementree/sources.tl) for more info
about that.

Using combinators, you can complete using LSP + LuaSnip with the
following:

```lua
local s = require"complementree.sources"
local cc = require"complementree.combinators"

lsp_and_luasnip = cc.combine(s.luasnip_matches {}, s.lsp_matches {})
```

## Filtering and sorting results

There are two special types of combinators: filters and comparators.

They simply change the order and filter the completion results, and
there are quite a bunch of them.

### Filters

- `prefix`: only keep suggestions that start with the current written
  word
- `strict_prefix`: same as `prefix` but be a strict prefix
  (different than written word)
- `amount(n)`: only take the first `n` suggestions

### Comparators

- `alphabetic`: sort results alphabetically
- `length`: sort results by length
If you have `romgrk/fzy-lua-native` installed, there will also be:
- `fzy`: sort based on the fuzzy score (case sensitive)
- `ifzy`: case insensitive version

## Query-based completion filters

In your setup calls, for a specific filetype completion, you can
specify your completion filters based on queries. What this will do is
use the query to determine whether the provided completion method
should be triggered. For example, those are equivalent:

```lua
-- This
{
  comment = defaults.lsp
}

-- Is equivalent to that
{
  ["(comment) @c"] = defaults.lsp
}

-- And that
{
  ["(comment) @c"] = { c = defaults.lsp }
}
```

As a key, you can specify a table, and in this case, depending on what
capture of the query the current cursor position matches, you will
trigger the corresponding completion method.

## Utilities

A threading-macro-like function in also provided for convenience,
which looks line `combinators.pipeline(source, ...)` and just applies
all combinators in the `...` one by one.

## Examples

Fuzzy LSP:
```lua
combinators.pipeline(sources.lsp_matches {}, comparators.fzy, filters.amount(6))
```

Fuzzy LSP and LuaSnip only if LSP returns something:
```lua
combinators.pipeline(combinators.optional(source.lsp_matches {}, source.luasnip_matches {}), comparators.fzy, filters.amount(6))
```

Look in the [defaults file](./teal/complementree/defaults.tl) for
more.
