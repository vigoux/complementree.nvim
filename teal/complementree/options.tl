local M = {}

function M.get<T>(defaults: T, user: T): T
  vim.tbl_deep_extend('force', defaults as {string: any}, user as {string: any})
  return defaults
end

return M
