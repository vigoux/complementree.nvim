local utils = require 'complementree.utils'
local M = {}

local function mk_comparator(func)
  return function(msource)
    return function(ltc, lnum)
      local orig, prefix = msource(ltc, lnum)
      local cmp_cache = {}
      table.sort(orig, function(a, b)
        local key = { a, b }

        if not cmp_cache[key] then
          cmp_cache[key] = func(utils.cword(a), utils.cword(b), prefix)
        end

        return cmp_cache[key]
      end)
      return orig, prefix
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
  local function mk_fzy(is_case_sensitive)
    return function(msource)
      return function(ltc, lnum)
        local orig, prefix = msource(ltc, lnum)
        local scores = {}
        local matching = {}
        for _, a in ipairs(orig) do
          local s = fzy.score(prefix, utils.cword(a), is_case_sensitive)
          if math.abs(s) ~= math.huge and prefix ~= utils.cword(a) then
            scores[a] = s
            table.insert(matching, a)
          end
        end
        table.sort(matching, function(a, b)
          return scores[a] > scores[b]
        end)
        return matching, prefix
      end
    end
  end
  M.fzy = mk_fzy(false)
  M.ifzy = mk_fzy(true)
end

return M
