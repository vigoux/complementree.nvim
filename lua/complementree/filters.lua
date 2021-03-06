local utils = require 'complementree.utils'
local M = {}

-- A function that returns a function that returns a function
local function mk_filter(func)
  return function(msource)
    return function(ltc, lnum)
      local orig, prefix = msource(ltc, lnum)
      local filtered = {}
      for i, v in ipairs(orig) do
        if func(i, v, prefix) then
          table.insert(filtered, v)
        end
      end
      return filtered, prefix
    end
  end
end

function M.amount(n)
  return mk_filter(function(i, _, _)
    return i <= n
  end)
end

M.prefix = mk_filter(function(_, v, prefix)
  return vim.startswith(utils.cword(v), prefix)
end)

M.strict_prefix = mk_filter(function(_, v, prefix)
  local w = utils.cword(v)
  return vim.startswith(w, prefix) and #w ~= #prefix
end)

M.substr = mk_filter(function(_, v, prefix)
  local w = utils.cword(v)
  return w:find(prefix, 1, true)
end)

return M
