local M = {}

local ccomp = require 'complementree.comparators'
local filter = require 'complementree.filters'
local utils = require 'complementree.utils'

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
    local max_p = nil
    for _, f in pairs(funcs) do
      local m, p = f(...)
      if not max_p then
        max_p = p
      end

      if max_p == p then
        vim.list_extend(matches, m)
      end
    end
    return matches, max_p
  end
end

function M.optional(mandat, opt)
  return function(ltc, lnum)
    local matches, prefix = mandat(ltc, lnum)
    if #matches > 0 then
      local m, _ = opt(ltc, lnum)
      vim.list_extend(matches, m)
      return matches, prefix
    else
      return {}, ""
    end
  end
end

function M.non_empty_prefix(func)
  return function(ltc, lnum)
    local compl, prefix = func(ltc, lnum)
    if #prefix > 1 then
      return complete(#ltc - #prefix + 1, compl)
    else
      return false
    end
  end
end

function M.wrap(func)
  return function(ltc, lnum)
    local compl, prefix = func(ltc, lnum)
    return complete(#ltc - #prefix + 1, compl)
  end
end

function M.pipeline(source, ...)
  local current = source
  for _, func in ipairs { ... } do
    current = func(current)
  end

  return M.wrap(current)
end

function M.chain(...)
  local funcs = { ... }
  return function(...)
    for _, f in pairs(funcs) do
      local c, pref = f(...)
      if #c > 0 then
        return c, pref
      end
    end
    return {}, ""
  end
end

return M
