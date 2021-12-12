local api = vim.api
local defaults = require"complementree.defaults"
local utils = require"complementree.utils"
local sources = require'complementree.sources'
local M = {}

local user_config = {
  default = defaults.dummy,
  vim = defaults.ins_completion "C-V"
}

function M.setup(config)
  if not config.default then
    error "This config does not have a default key."
  end
  user_config = config
end

function M.print_config()
  print(vim.inspect(user_config))
end

local function node_type_at_cursor(line_to_cursor, linenr)
  local ok, tsutils = pcall(require, "nvim-treesitter.ts_utils")
  if not ok then return end

  local col = vim.fn.match(line_to_cursor, '\\s*\\k*$')
  local root = tsutils.get_root_for_position(linenr, col)
  if not root then return end

  local node = root:named_descendant_for_range(linenr - 1, col - 1, linenr - 1, col - 1)
  if not node then return end

  return node:type()
end

function M.complete()
  -- Only refresh when not restarting
  if vim.fn.pumvisible() == 0 then
    sources.invalidate_cache()
  end
  if not vim.fn.mode():find('i') then return false end

  local bufnr = api.nvim_get_current_buf()
  local ft = api.nvim_buf_get_option(bufnr, "filetype")

  local line = api.nvim_get_current_line()
  local lnum, cursor_pos = unpack(api.nvim_win_get_cursor(0))
  local line_to_cursor = line:sub(1, cursor_pos)
  local col = vim.fn.match(line_to_cursor, '\\k*$') + 1
  local preffix = line:sub(col, cursor_pos)

  -- The source signature is
  -- line_content, line_content_up_to_cursor, preffix, column

  local ft_completion = user_config[ft] or user_config.default
  if ft_completion then
    if type(ft_completion) == "table" then
      local t = node_type_at_cursor(line_to_cursor, lnum)
      if not t then return end
      local sub_completion = ft_completion[t] or ft_completion.default
      if sub_completion then
        return sub_completion(line, line_to_cursor, preffix, col)
      end
    elseif type(ft_completion) == "function" then
      return ft_completion(line, line_to_cursor, preffix, col)
    end
  end
  return false
end

function M._CompleteDone()
  local completed_item = api.nvim_get_vvar('completed_item')
  if not completed_item
     or not completed_item.user_data
     or not completed_item.user_data.source then return end
  local func = sources.complete_done_cbs[completed_item.user_data.source]
  if func then
    func(completed_item)
  end
end

function M._InsertCharPre()
  if vim.fn.pumvisible() == 1 then
    local char = api.nvim_get_vvar 'char'
    if char:find"%s" then
      -- Whitespace, so accept this choice and stop here
      utils.feed '<C-Y>'
    else
      -- Refresh completion after this char is inserted
      vim.schedule(function()
        M.complete()
      end)
    end
  end
end

return M

