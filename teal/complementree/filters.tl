local utils = require 'complementree.utils'

local record Filters
  amount: Pipe
  prefix: Pipe
  strict_prefix: Pipe
  substr: Pipe
end

local type Filter = function(integer, CompleteItem, string): boolean

-- A function that returns a function that returns a function
local function mk_filter(func: Filter): Pipe
  return function(msource: Source): Source
    return function(ltc: string, lnum: integer): {CompleteItem}, string
      local orig, prefix = msource(ltc, lnum)
      local filtered: {CompleteItem} = {}
      for i, v in ipairs(orig) do
        if func(i, v, prefix) then
          table.insert(filtered, v)
        end
      end
      return filtered, prefix
    end
  end
end

function Filters.amount(n: integer): Pipe
  return mk_filter(function(i: integer, _: CompleteItem, _: string): boolean
    return i <= n
  end)
end

Filters.prefix = mk_filter(function(_: integer, v: CompleteItem, prefix: string): boolean
  return vim.startswith(utils.cword(v), prefix)
end)

Filters.strict_prefix = mk_filter(function(_: integer, v: CompleteItem, prefix: string): boolean
  local w = utils.cword(v)
  return vim.startswith(w, prefix) and #w ~= #prefix
end)

Filters.substr = mk_filter(function(_: integer, v: CompleteItem, prefix: string): boolean
  local w = utils.cword(v)
  local start = w:find(prefix, 1, true)
  return start ~= nil
end)

return Filters
