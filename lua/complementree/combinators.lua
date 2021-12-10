local M = {}

local ccomp = require'complementree.comparators'
local filter = require'complementree.filters'
local utils = require'complementree.utils'

local function filter_sort(matches, preffix, comparator, filterf)
  local filtered = {}
  for i,v in ipairs(matches) do
    if filterf(i, v, preffix) then
      table.insert(filtered, v)
    end
  end
  local cmp_cache = {}
  table.sort(filtered, function(a,b)
    local key = {a, b}

    if not cmp_cache[key] then
      cmp_cache[key] = comparator(a, b, preffix)
    end

    return cmp_cache[key]
  end)

  return filtered
end

local function complete(col, matches)
  if matches and #matches > 0 then
    vim.fn.complete(col, matches)
    return true
  else
    return false
  end
end

function M.combine(...)
  local funcs = { ... }
  return function(...)
    local matches = {}
    for _,f in pairs(funcs) do
      local m = f(...)
      vim.list_extend(matches, m)
    end
    return matches
  end
end

function M.optional(mandat, opt)
  return function(line, ltc, preffix, col)
    local matches = mandat(line, ltc, preffix, col)
    if #matches > 0 then
      vim.list_extend(matches, opt(line, ltc, preffix, col))
      return matches
    else
      return {}
    end
  end
end

function M.non_empty_preffix(func)
  return function(line, ltc, preffix, col)
    if #preffix > 1 then
      return complete(col, func(line, ltc, preffix, col))
    else
      return false
    end
  end
end

function M.wrap(func)
  return function(line, line_to_cursor, preffix, col)
    local compl = func(line, line_to_cursor, preffix, col)
    return complete(col, compl)
  end
end

function M.pipeline(source, ...)
  local current = source
  for _,func in ipairs { ... } do
    current = func(current)
  end

  return M.wrap(current)
end

return M
