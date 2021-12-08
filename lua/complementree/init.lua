local api = vim.api
local sources = require"complementree.sources"
local M = {}

local user_config = {
  default = sources.dummy,
  vim = sources.ins_completion "C-V"
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

function M.complete()
  if not vim.fn.mode():find('i') then return false end

  local bufnr = api.nvim_get_current_buf()
  local ft = api.nvim_buf_get_option(bufnr, "filetype")

  local line = api.nvim_get_current_line()
  local cursor_pos = api.nvim_win_get_cursor(0)[2]
  local line_to_cursor = line:sub(1, cursor_pos)
  local col = vim.fn.match(line_to_cursor, '\\k*$') + 1
  local preffix = line:sub(col, cursor_pos)

  local ft_completion = user_config[ft] or user_config.default
  if ft_completion then
    if type(ft_completion) == "table" then
      local ok, tsutils = pcall(require, "nvim-treesitter.ts_utils")
      if not ok then return false end

      local node = tsutils.get_node_at_cursor()
      if not node then return false end

      local sub_completion = ft_completion[node:type()] or ft_completion.default
      if sub_completion then
        return sub_completion(line, line_to_cursor, preffix, col)
      end
    elseif type(ft_completion) == "function" then
      return ft_completion(line, line_to_cursor, preffix, col)
    end
  end
  return false
end

return M
