local api = vim.api

local record Prefix
end

function Prefix.lua_regex(regex: string, line: string): string
  local pref_start = line:find(regex)
  local prefix = line:sub(pref_start)

  return prefix
end

function Prefix.vim_keyword(line: string): string
  local pref_start = vim.fn.match(line, '\\k*$') + 1
  local prefix = line:sub(pref_start)

  return prefix
end

local record Utils
  prefix: Prefix
end

function Utils.feed(codes: string)
  api.nvim_feedkeys(api.nvim_replace_termcodes(codes, true, true, true), 'm', true)
end

function Utils.cword(complete_item: CompleteItem): string
  return (complete_item.abbr or complete_item.word)
end

function Utils.make_relative_path(path: string, root: string): string
  if vim.startswith(path, root) then
    local baselen = #root
    if path:sub(0, baselen) == root then
      path = path:sub(baselen + 2)
    end
  end
  return path
end

return Utils
