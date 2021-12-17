local M = {}
local api = vim.api

function M.feed(codes)
  api.nvim_feedkeys(api.nvim_replace_termcodes(codes, true, true, true), 'm', true)
end

function M.cword(complete_item)
  return (complete_item.word or complete_item.abbr)
end

function M.make_relative_path(path, root)
  local baselen = #root
  if path:sub(0, baselen) == root then
    path = path:sub(baselen + 2)
  end
  return path
end

return M
