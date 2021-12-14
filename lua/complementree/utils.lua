local M = {}
local api = vim.api
local uv = vim.loop

function M.feed(codes)
  api.nvim_feedkeys(
  api.nvim_replace_termcodes(codes, true, true, true),
    "m",
    true
  )
end

function M.cword(complete_item)
  return (complete_item.word or complete_item.abbr)
end

M.make_relative_path = function(path, root)
  local baselen = #root
  if path:sub(0, baselen) == root then
      path = path:sub(baselen+2)
  end
  return path
end

local function get_os_file_separator()
  local os = string.lower(jit.os)
  if os == "linux" or os == "osx" or os == "bsd" then
    return "/"
  else
    return "\\"
  end
end

local os_sep = get_os_file_separator()
M.scan_dir = function(dir, list, opts)
  list = list or {}

  local req = uv.fs_scandir(dir)
  if not req then
    return list
  end

  -- TODO: implement ignore hidden dirs
  local opts = {}
  local ignore_hidden = opts.ignore_hidden or true
  local normalize_paths = opts.normalize_paths or true
  local max_dir_depth = opts.max_depth or 8

  local function iter()
    return uv.fs_scandir_next(req)
  end

  local sub_dirs = {}
  for name, ftype in iter do
    if ftype == "directory" then
      sub_dirs[#sub_dirs + 1] = name
    elseif ftype == "file" then
      list[#list + 1] = dir .. os_sep .. name
    end
  end

  for _, sd in ipairs(sub_dirs) do
    if not(ignore_hidden and sd:sub(1, 1) == ".") then
      list = M.scan_dir(dir .. os_sep .. sd, list)
    end
  end

  return list
end

return M
