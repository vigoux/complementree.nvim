local M = {}
local api = vim.api
local uv = vim.loop

local os = string.lower(jit.os)
local os_sep = (os == "linux" or os == "osx" or os == "bsd") and "/" or "\\"

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

local scandir_default_opts = {
  ignore_hidden = true,
  max_depth = 8,
  match_patterns = {},
}

M.scan_dir = function(root_dir, opts, list, depth)
  local tbl_isempty = vim.tbl_isempty
  opts = opts or scandir_default_opts
  list = list or {}
  depth = depth or 1

  local function is_ignored_path(path)
    return (opts.ignore_hidden and path:sub(1, 1) == ".")
  end

  local function is_matched_filetype(path)
    for _, pattern in ipairs(opts.match_patterns) do
      if path:match(pattern) then
        return true
      end
    end
    return false
  end

  local req = uv.fs_scandir(root_dir)
  if not req then
    return list
  end

  local function iter()
    return uv.fs_scandir_next(req)
  end

  local sub_dirs = {}
  for path, ftype in iter do
    if ftype == "directory" then
      if not is_ignored_path(path) then
        sub_dirs[#sub_dirs + 1] = path
      end
    elseif ftype == "file" then
      if not is_ignored_path(path) then
        if not tbl_isempty(opts.match_patterns) and not is_matched_filetype(path) then
          goto continue
        end
        list[#list + 1] = ("%s%s%s"):format(root_dir, os_sep, path)
        ::continue::
      end
    end
  end

  if depth <= opts.max_depth then
    local subdir_path
    for _, path in ipairs(sub_dirs) do
      subdir_path = ("%s%s%s"):format(root_dir, os_sep, path)
      list = M.scan_dir(subdir_path, opts, list, depth + 1)
    end
  end

  return list
end

return M
