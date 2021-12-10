local utils = require'complementree.utils'
local M = {}

local function mk_comparator(func)
  return function(msource)
    return function(line, ltc, preffix, col)
      local orig = msource(line, ltc, preffix, col)
      local cmp_cache = {}
      table.sort(orig, function(a,b)
        local key = {a, b}

        if not cmp_cache[key] then
          cmp_cache[key] = func(utils.cword(a), utils.cword(b), preffix)
        end

        return cmp_cache[key]
      end)
      return orig
    end
  end
end

M.alphabetic = mk_comparator(function(a, b)
  return a < b
end)

M.length = mk_comparator(function(a, b)
  return #a < #b
end)

local ok_fzy, fzy = pcall(require, 'fzy-lua-native')
if ok_fzy then
  M.fzy = mk_comparator(function(a, b, prefix)
    if prefix ~= nil then
      return fzy.score(prefix, a, false) > fzy.score(prefix, b, false)
    else
      return a < b
    end
  end)

  M.ifzy = mk_comparator(function(a, b, prefix)
    if prefix ~= nil then
      return fzy.score(prefix, a, true) > fzy.score(prefix, b, true)
    else
      return a < b
    end
  end)
end

return M
