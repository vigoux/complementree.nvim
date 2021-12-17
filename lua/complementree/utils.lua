local M = {}
local api = vim.api

function M.feed(codes)
  api.nvim_feedkeys(api.nvim_replace_termcodes(codes, true, true, true), 'm', true)
end

function M.cword(complete_item)
  return (complete_item.word or complete_item.abbr)
end

function M.make_relative_path(path, root)
  if vim.startswith(path, root) then
    local baselen = #root
    if path:sub(0, baselen) == root then
      path = path:sub(baselen + 2)
    end
  end
  return path
end

local P = {}

function P.lua_regex(regex, line)
  local pref_start = line:find(regex)
  local prefix = line:sub(pref_start)

  return prefix
end

function P.vim_keyword(line)
  local pref_start = vim.fn.match(line, '\\k*$') + 1
  local prefix = line:sub(pref_start)

  return prefix
end


M.prefix = P

return M
