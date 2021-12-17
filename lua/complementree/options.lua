local M = {}

function M.get(defaults, user)
  vim.tbl_deep_extend('force', defaults, user)
  return defaults
end

return M
