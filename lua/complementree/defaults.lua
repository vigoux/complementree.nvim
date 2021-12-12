local M = {}

local comb = require'complementree.combinators'
local sources = require'complementree.sources'
local filters = require'complementree.filters'
local comp = require'complementree.comparators'
local utils = require'complementree.utils'

function M.ins_completion(mode)
  return function()
    utils.feed(string.format("<C-X><%s>", mode))
    return vim.fn.pumvisible() == 1
  end
end

function M.dummy()
  -- Does nothing
end

M.luasnip = comb.pipeline(sources.luasnip_matches, filters.preffix, comp.alphabetic)

M.lsp = comb.pipeline(sources.lsp_matches, filters.preffix, comp.alphabetic)

return M