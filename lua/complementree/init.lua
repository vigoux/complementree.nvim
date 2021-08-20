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
  local bufnr = api.nvim_get_current_buf()
  local ft = api.nvim_buf_get_option(bufnr, "filetype")

  local ft_completion = user_config[ft] or user_config.default
  if ft_completion then
    if type(ft_completion) == "table" then
      local ok, tsutils = pcall(require, "nvim-treesitter.ts_utils")
      if not ok then return end

      local node = tsutils.get_node_at_cursor()
      if not node then return end

      local sub_completion = ft_completion[node:type()] or ft_completion.default
      if sub_completion then
        sub_completion(api.nvim_get_current_line())
      end
    elseif type(ft_completion) == "function" then
      ft_completion(api.nvim_get_current_line())
    end
  end
end

return M
