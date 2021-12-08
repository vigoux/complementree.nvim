local M = {}

local utils = require'complementree.utils'
local api = vim.api
local lsp = vim.lsp

function M.ins_completion(mode)
  return function()
    utils.feed(string.format("<C-X><%s>", mode))
    return vim.fn.pumvisible() == 1
  end
end

function M.dummy()
  -- Does nothing
end

function M.luasnip_matches(_, _, preffix, _)
  local snippets = require'luasnip'.available()

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
    if vim.startswith(s.trigger, preffix) then
      table.insert(items, {
        word = s.trigger,
        abbr = s.name,
        kind = "S",
        menu = table.concat(s.description or {}),
        icase = 1,
        dup = 1,
        empty = 1,
        user_data = { source = "luasnip" }
      })
    end
  end

  vim.tbl_map(add_snippet, snippets.all)
  vim.tbl_map(add_snippet, snippets[api.nvim_buf_get_option(0, 'filetype')])

  return items
end

-- Shamelessly stollen from https://github.com/mfussenegger/nvim-lsp-compl with small adaptations
function M.lsp_matches(line, line_to_cursor, preffix, col)
  local params = lsp.util.make_position_params()
  local result_all, err = lsp.buf_request_sync(0, 'textDocument/completion', params)
  assert(not err, vim.inspect(err))
  if not result_all then return end

  local matches = {}
  for client_id,result in pairs(result_all) do
    local items = lsp.util.extract_completion_items(result.result)
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
      if vim.startswith(word, preffix) and word ~= preffix then
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
          user_data = item
        })
      end
    end
  end
  return matches
end

local function apply_snippet(item, suffix)
  local luasnip = require"luasnip"
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
  if not client then return end

  local resolveEdits = (client.server_capabilities.completionProvider or {}).resolveProvider

  local tidy = function() end
  local suffix = nil
  if expand_snippet then
    local line = api.nvim_buf_get_lines(bufnr, lnum, lnum + 1, true)[1]
    tidy = function()
      -- Remove the already inserted word
      local start_char = col - #completed_item.word
      local l = line
      api.nvim_buf_set_text(bufnr, lnum, start_char, lnum, #l, {''})
    end
    suffix = line:sub(col + 1)
  end

  if item.additionalTextEdits then
    tidy()
    lsp.util.apply_text_edits(item.additionalTextEdits, bufnr)
    if expand_snippet then
      apply_snippet(item, suffix)
    end
  elseif resolveEdits and type(item) == "table" then
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

-- Combinators

function M.preffix_guard(source)
  return function(line, ltc, preffix, col)
    if #preffix > 1 then
      return source(line, ltc, preffix, col)
    else
      return false
    end
  end
end

function M.wrap(func)
  return function(line, line_to_cursor, preffix, col)
    local compl = func(line, line_to_cursor, preffix, col)
    if compl and #compl > 0 then
      table.sort(compl, function(a, b)
        return (a.word or a.abbr) < (b.word or b.abbr)
      end)
      vim.fn.complete(col, func(line, line_to_cursor, preffix, col))
      return true
    else
      return false
    end
  end
end

function M.combine(...)
  local funcs = { ... }
  return M.wrap(function(...)
    local matches = {}
    for _,f in pairs(funcs) do
      local m = f(...)
      vim.list_extend(matches, m)
    end
    return matches
  end)
end

-- Defaults

M.luasnip = M.wrap(M.luasnip_matches)

M.lsp = M.wrap(M.lsp_matches)

local function luasnip_completedone(_)
  if require'luasnip'.expandable() then
    require'luasnip'.expand()
  end
end

local complete_done_cbs = {
  lsp = lsp_completedone,
  luasnip = luasnip_completedone
}

function M._CompleteDone()
  local completed_item = api.nvim_get_vvar('completed_item')
  if not completed_item
     or not completed_item.user_data
     or not completed_item.user_data.source then return end
  local func = complete_done_cbs[completed_item.user_data.source]
  if func then
    func(completed_item)
  end
end

return M
