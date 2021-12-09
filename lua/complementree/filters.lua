local utils = require'complementree.utils'
local M = {}

function M.amount(n)
  return function(i, _, _)
    return i <= n
  end
end

function M.preffix()
  return function(_, v, preffix)
    return vim.startswith(utils.cword(v), preffix)
  end
end

function M.strict_preffix()
  return function(_, v, preffix)
    local w = utils.cword(v)
    return vim.startswith(w, preffix) and #w ~= #preffix
  end
end

return M
