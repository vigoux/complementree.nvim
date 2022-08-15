local M = {}

local function complete(col: integer, matches: {CompleteItem}): boolean
  if matches and #matches > 0 then
    vim.fn.complete(col, matches)
    return true
  else
    return false
  end
end

function M.combine(...: Source): Source
  local funcs = { ... }
  return function(ltc: string, lnum: integer): {CompleteItem}, string
    local matches: {CompleteItem} = {}
    local coherent_p: string
    for _, f in ipairs(funcs) do
      local m, p = f(ltc, lnum)
      if not coherent_p then
        coherent_p = p
      end

      if coherent_p == p then
        vim.list_extend(matches, m)
      end
    end
    return matches, coherent_p
  end
end

function M.optional(mandat: Source, opt: Source): Source
  return function(ltc: string, lnum: integer): {CompleteItem}, string
    local matches, prefix = mandat(ltc, lnum)
    if #matches > 0 then
      local m, p = opt(ltc, lnum)
      if p == prefix then
        vim.list_extend(matches, m)
      end
      return matches, prefix
    else
      return {}, ''
    end
  end
end

-- TODO(vigoux): do we even need this anymore ?
function M.non_empty_prefix(func: Source): Completor
  return function(ltc: string, lnum: integer): boolean
    local compl, prefix = func(ltc, lnum)
    if #prefix > 1 then
      return complete(#ltc - #prefix + 1, compl)
    else
      return false
    end
  end
end

function M.wrap(func: Source): Completor
  return function(ltc: string, lnum: integer): boolean
    local compl, prefix = func(ltc, lnum)
    return complete(#ltc - #prefix + 1, compl)
  end
end

function M.pipeline(source: Source, ...: Pipe): Completor
  local current = source
  for _, func in ipairs { ... } do
    current = func(current)
  end

  return M.wrap(current)
end

function M.chain(...: Source): Source
  local funcs = { ... }
  return function(ltc: string, lnum: integer): {CompleteItem}, string
    for _, f in ipairs(funcs) do
      local c, pref = f(ltc, lnum)
      if #c > 0 then
        return c, pref
      end
    end
    return {}, ''
  end
end

return M
