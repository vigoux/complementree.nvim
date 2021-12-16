local M = {}
local api = vim.api
local uv = vim.loop

function M.feed(codes)
  api.nvim_feedkeys(api.nvim_replace_termcodes(codes, true, true, true), 'm', true)
end

function M.cword(complete_item)
  return (complete_item.word or complete_item.abbr)
end

function M.read_file(path)
  local fd = assert(uv.fs_open(path, "r", 438))
  local stat = assert(uv.fs_fstat(fd))
  local data = assert(uv.fs_read(fd, stat.size, 0))
  assert(uv.fs_close(fd))
  return data
end

return M
