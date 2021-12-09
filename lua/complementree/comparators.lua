local utils = require'complementree.utils'
local M = {}

function M.alphabetic(a, b)
  return utils.cword(a) < utils.cword(b)
end

function M.length(a, b)
  return #utils.cword(a) < #utils.cword(b)
end

local ok_fzy, fzy = pcall(require, 'fzy-lua-native')
if ok_fzy then
  function M.fzy(a, b, prefix)
    if prefix ~= nil then
      return fzy.score(prefix, utils.cword(a), false) > fzy.score(prefix, utils.cword(b), false)
    else
      return M.alphabetic(a, b)
    end
  end

  function M.ifzy(a, b, prefix)
    if prefix ~= nil then
      return fzy.score(prefix, utils.cword(a), true) > fzy.score(prefix, utils.cword(b), true)
    else
      return M.alphabetic(a, b)
    end
  end
end

local function this_is_a_test()
  -- foobar
  print'boo'
end

return M
