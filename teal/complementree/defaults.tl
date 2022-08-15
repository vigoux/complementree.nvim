local record Defaults
  ins_completion: function(string): Completor
  dummy: Completor
  luasnip: Completor
  lsp: Completor
  ctags: Completor
  filepath: Completor
end

local comb = require 'complementree.combinators'
local sources = require 'complementree.sources'
local filters = require 'complementree.filters'
local comp = require 'complementree.comparators'
local utils = require 'complementree.utils'

function Defaults.ins_completion(mode: string): Completor
  return function(): boolean
    utils.feed(string.format('<C-X><%s>', mode))
    return vim.fn.pumvisible() == 1
  end
end

function Defaults.dummy(): boolean
  -- Does nothing
end

Defaults.luasnip = comb.pipeline(sources.luasnip_matches {}, filters.prefix, comp.alphabetic)

Defaults.lsp = comb.pipeline(sources.lsp_matches {}, filters.prefix, comp.alphabetic)

Defaults.ctags = comb.pipeline(sources.ctags_matches {}, filters.prefix, comp.alphabetic)

Defaults.filepath = comb.pipeline(sources.filepath_matches {}, filters.substr, comp.alphabetic)

return Defaults
