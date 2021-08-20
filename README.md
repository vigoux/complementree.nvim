# Complementree.nvim: a tree-sitter powered completion framework

This plugin is a _completion framework_ built for neovim, and powered
by tree-sitter.

## Installation

This plugin does not have any dependency.

```lua
use 'vigoux/complementree.nvim'
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
