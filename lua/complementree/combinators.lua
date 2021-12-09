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

local function complete(col, matches, preffix, comparator, filterf)
  local filtered = filter_sort(matches, preffix, comparator, filterf)
  if filtered and #filtered > 0 then
    vim.fn.complete(col, filtered)
    return true
  else
    return false
  end
end

local function desc_to_msource(desc)
  if type(desc) == 'table' and desc.matches then
    return desc.matches, desc.comparator or ccomp.alphabetic, desc.filter or filter.preffix
  elseif type(desc) == 'function' then
    return desc, ccomp.alphabetic, filter.preffix
  else
    error('Invalid description')
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

function M.optional(mandat, opt, comparator, filterf)
  -- TODO(vigoux): optimize this a bit, as we will filter/sort the mandatory results twice
  return function(line, ltc, preffix, col)
    local matches = mandat(line, ltc, preffix, col)
    matches = filter_sort(matches, preffix, comparator or ccomp.alphabetic, filterf or filter.preffix)
    if #matches > 0 then
      vim.list_extend(matches, opt(line, ltc, preffix, col))
      return complete(col, matches, preffix, comparator, filterf)
    else
      return false
    end
  end
end

function M.non_empty_preffix(desc)
  local func, comparator, filterf = desc_to_msource(desc)
  return function(line, ltc, preffix, col)
    if #preffix > 1 then
      return complete(col, func(line, ltc, preffix, col), preffix, comparator, filterf)
    else
      return false
    end
  end
end

function M.wrap(desc)
  local func, comparator, filterf = desc_to_msource(desc)
  return function(line, line_to_cursor, preffix, col)
    local compl = func(line, line_to_cursor, preffix, col)
    return complete(col, compl, preffix, comparator, filterf)
  end
end

return M
