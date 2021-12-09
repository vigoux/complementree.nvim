local M = {}

local function complete(col, matches)
  if matches and #matches > 0 then
    table.sort(matches, function(a, b)
      return (a.word or a.abbr) < (b.word or b.abbr)
    end)
    vim.fn.complete(col, matches)
    return true
  else
    return false
  end
end

function M.wrap(func)
  return function(line, line_to_cursor, preffix, col)
    local compl = func(line, line_to_cursor, preffix, col)
    return complete(col, compl)
  end
end

function M.combine(...)
  local funcs = { ... }
  return function(line, ltc, preffix, col)
    local matches = {}
    for _,f in pairs(funcs) do
      local m = f(line, ltc, preffix, col)
      vim.list_extend(matches, m)
    end
    return complete(col, matches)
  end
end

function M.non_empty_preffix(source)
  return function(line, ltc, preffix, col)
    if #preffix > 1 then
      return M.wrap(source(line, ltc, preffix, col))
    else
      return false
    end
  end
end

function M.strictly_different(source)
  return function(line, ltc, preffix, col)
    local matches = source(line, ltc, preffix, col)
    if #matches == 1 and (matches[1].word or matches[1].abbr) == preffix then
      return false
    else
      return complete(col, matches)
    end
  end
end


return M
