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

local function get_luasnip(preffix)
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
function M.lsp(line, line_to_cursor, preffix, col)
  local params = lsp.util.make_position_params()
  local _, _ = lsp.buf_request(0, 'textDocument/completion', params, function(err, _, result, client_id)
    assert(not err, vim.inspect(err))
    if not result then return end

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
    vim.list_extend(matches, get_luasnip(preffix))
    table.sort(matches, function(a, b)
      return (a.word or a.abbr) < (b.word or b.abbr)
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

function M.wrap(func)
  return function(line, line_to_cursor, preffix, col)
    vim.fn.complete(col, func(line, line_to_cursor, preffix, col))
  end
end

M.luasnip = M.wrap(function(_, _, preffix, _)
  return get_luasnip(preffix)
end)

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
