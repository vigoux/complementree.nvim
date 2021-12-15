local M = {}

local utils = require 'complementree.utils'
local comb = require 'complementree.combinators'
local api = vim.api
local lsp = vim.lsp

local cache = {}

function M.invalidate_cache()
  cache = {}
end

local function cached(kind, func)
  return function(...)
    if not cache[kind] then
      cache[kind] = {func(...)}
    end
    local m,p = unpack(cache[kind])
    local new = {}
    for _, v in pairs(m) do
      table.insert(new, v)
    end
    return new, p
  end
end

M.luasnip_matches = cached('luasnip', function(line_to_cursor, _)
  local snippets = require('luasnip').available()

  local pref_start = line_to_cursor:find '%w*$'
  local prefix = line_to_cursor:sub(pref_start)

  local items = {}

  -- Luasnip format:
  -- {
  --  description = table(string),
  --  name = string,
  --  regTrig = bool,
  --  trigger = string,
  --  wordTrig = bool
  -- }
  local function add_snippet(s)
    table.insert(items, {
      word = s.trigger,
      abbr = s.name,
      kind = 'S',
      menu = table.concat(s.description or {}),
      icase = 1,
      dup = 1,
      empty = 1,
      user_data = { source = 'luasnip' },
    })
  end

  vim.tbl_map(add_snippet, snippets.all)
  vim.tbl_map(add_snippet, snippets[api.nvim_buf_get_option(0, 'filetype')])

  return items, prefix
end)

-- Shamelessly stollen from https://github.com/mfussenegger/nvim-lsp-compl with small adaptations
M.lsp_matches = cached('lsp', function(line_to_cursor, lnum)

  -- For lsp determining the preffix is painful, but thanks to the great @mfussenegger, we can fix
  -- this all !
  local function adjust_start_col(lnum, line, items, encoding)
    local min_start_char = nil

    for _, item in pairs(items) do
      if item.textEdit and item.textEdit.range.start.line == lnum - 1 then
        if min_start_char and min_start_char ~= item.textEdit.range.start.character then
          return nil
        end
        min_start_char = item.textEdit.range.start.character
      end
    end
    if min_start_char then
      if encoding == 'utf-8' then
        return min_start_char + 1
      else
        return vim.str_byteindex(line, min_start_char, encoding == 'utf-16') + 1
      end
    else
      return nil
    end
  end

  local params = lsp.util.make_position_params()
  local result_all, err = lsp.buf_request_sync(0, 'textDocument/completion', params)
  assert(not err, vim.inspect(err))
  if not result_all then
    return
  end

  local matches = {}
  local start_col = vim.fn.match(line_to_cursor, '\\k*$') + 1
  for client_id, result in pairs(result_all) do
    local client = lsp.get_client_by_id(client_id)
    local items = lsp.util.extract_completion_items(result.result)

    local tmp_col = adjust_start_col(lnum, line_to_cursor, items, client.offset_encoding or 'utf-16')
    if tmp_col and tmp_col < start_col then
      start_col = tmp_col
    end

    for _, item in pairs(items or {}) do
      local kind = lsp.protocol.CompletionItemKind[item.kind] or ''
      local word
      if kind == 'Snippet' then
        word = item.label
      elseif item.insertTextFormat == 2 then
        if item.textEdit then
          word = item.insertText or item.textEdit.newText
        elseif item.insertText then
          if #item.label < #item.insertText then
            word = item.label
          else
            word = item.insertText
          end
        else
          word = item.label
        end
      else
        word = (item.textEdit and item.textEdit.newText) or item.insertText or item.label
      end
      item.client_id = client_id
      item.source = 'lsp'
      table.insert(matches, {
        word = word,
        abbr = item.label,
        kind = kind,
        menu = item.detail or '',
        icase = 1,
        dup = 1,
        empty = 1,
        user_data = item,
      })
    end
  end
  local prefix = line_to_cursor:sub(start_col)
  return matches, prefix
end)

local function apply_snippet(item, suffix)
  local luasnip = require 'luasnip'
  if item.textEdit then
    luasnip.lsp_expand(item.textEdit.newText .. suffix)
  elseif item.insertText then
    luasnip.lsp_expand(item.insertText .. suffix)
  elseif item.label then
    luasnip.lsp_expand(item.label .. suffix)
  end
end

local function lsp_completedone(completed_item)
  local lnum, col = unpack(api.nvim_win_get_cursor(0))
  lnum = lnum - 1
  local item = completed_item.user_data
  local bufnr = api.nvim_get_current_buf()
  local expand_snippet = item.insertTextFormat == 2
  local client = lsp.get_client_by_id(item.client_id)
  if not client then
    return
  end

  local resolveEdits = (client.server_capabilities.completionProvider or {}).resolveProvider

  local tidy = function() end
  local suffix = nil
  if expand_snippet then
    local line = api.nvim_buf_get_lines(bufnr, lnum, lnum + 1, true)[1]
    tidy = function()
      -- Remove the already inserted word
      local start_char = col - #completed_item.word
      local l = line
      api.nvim_buf_set_text(bufnr, lnum, start_char, lnum, #l, { '' })
    end
    suffix = line:sub(col + 1)
  end

  if item.additionalTextEdits then
    tidy()
    lsp.util.apply_text_edits(item.additionalTextEdits, bufnr)
    if expand_snippet then
      apply_snippet(item, suffix)
    end
  elseif resolveEdits and type(item) == 'table' then
    local v = client.request_sync('completionItem/resolve', item, 1000, bufnr)
    assert(not v.err, vim.inspect(v.err))
    if v.result.additionalTextEdits then
      tidy()
      tidy = function() end
      lsp.util.apply_text_edits(v.result.additionalTextEdits, bufnr)
    end
    if expand_snippet then
      tidy()
      apply_snippet(item, suffix)
    end
  elseif expand_snippet then
    tidy()
    apply_snippet(item, suffix)
  end
end

-- CompleteDone handlers

local function luasnip_completedone(_)
  if require('luasnip').expandable() then
    require('luasnip').expand()
  end
end

M.complete_done_cbs = {
  lsp = lsp_completedone,
  luasnip = luasnip_completedone,
}

return M
