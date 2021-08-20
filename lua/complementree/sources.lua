local M = {}

local api = vim.api
local lsp = vim.lsp

function M.ins_completion(mode)
  return function()
    api.nvim_feedkeys(
      api.nvim_replace_termcodes(string.format("<C-X><%s>", mode), true, true, true),
      "m",
      true
    )
  end
end

function M.dummy()
  -- Does nothing
end


-- Shamelessly stollen from https://github.com/mfussenegger/nvim-lsp-compl with small adaptations
function M.lsp()
  local params = lsp.util.make_position_params()
  local _, _ = lsp.buf_request(0, 'textDocument/completion', params, function(err, _, result, client_id)
    assert(not err, vim.inspect(err))
    if not result then return end

    local cursor_pos = api.nvim_win_get_cursor(0)[2]
    local line = api.nvim_get_current_line()
    local line_to_cursor = line:sub(1, cursor_pos)
    local col = vim.fn.match(line_to_cursor, '\\k*$') + 1
    local preffix = line:sub(col, cursor_pos)

    local items = lsp.util.extract_completion_items(result)
    if not items or #items == 0 then return end
    local matches = {}
    for _, item in pairs(items) do
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
      if vim.startswith(word, preffix) then
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
    table.sort(matches, function(a, b)
      return (a.user_data.sortText or a.user_data.label) < (b.user_data.sortText or b.user_data.label)
    end)
    vim.fn.complete(col, matches)
  end)
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
    local _, _ = lsp.buf_request(0, 'completionItem/resolve', item, function(err, _, result)
      assert(not err, vim.inspect(err))
      if result.additionalTextEdits then
        tidy()
        tidy = function() end
        lsp.util.apply_text_edits(result.additionalTextEdits, bufnr)
      end
      if expand_snippet then
        tidy()
        apply_snippet(item, suffix)
      end
    end)
  elseif expand_snippet then
    tidy()
    apply_snippet(item, suffix)
  end
end

local complete_done_cbs = {
  lsp = lsp_completedone
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
