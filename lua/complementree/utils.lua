local M = {}
local api = vim.api
local uv = vim.loop

local os = string.lower(jit.os)
local os_sep = (os == 'linux' or os == 'osx' or os == 'bsd') and '/' or '\\'

function M.feed(codes)
  api.nvim_feedkeys(api.nvim_replace_termcodes(codes, true, true, true), 'm', true)
end

function M.cword(complete_item)
  return (complete_item.word or complete_item.abbr)
end

M.make_relative_path = function(path, root)
  local baselen = #root
  if path:sub(0, baselen) == root then
    path = path:sub(baselen + 2)
  end
  return path
end

return M
