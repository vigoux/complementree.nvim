local utils = require'complementree.utils'
local M = {}

-- A function that returns a function that returns a function
local function mk_filter(func)
  return function(msource)
    return function(line, ltc, preffix, col)
      local orig = msource(line, ltc, preffix, col)
      local filtered = {}
      for i,v in ipairs(orig) do
        if func(i, v, preffix) then
          table.insert(filtered, v)
        end
      end
      return filtered
    end
  end
end

function M.amount(n)
  return mk_filter(function(i, _, _)
    return i <= n
  end)
end

M.preffix = mk_filter(function(_, v, preffix)
  return vim.startswith(utils.cword(v), preffix)
end)

M.strict_preffix = mk_filter(function(_, v, preffix)
  local w = utils.cword(v)
  return vim.startswith(w, preffix) and #w ~= #preffix
end)

return M
