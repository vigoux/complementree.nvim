local api = vim.api
local defaults = require 'complementree.defaults'
local utils = require 'complementree.utils'
local sources = require 'complementree.sources'
local tsutils = require 'nvim-treesitter.ts_utils'
local M = {}

local user_config = {
  default = defaults.dummy,
  vim = defaults.ins_completion 'C-V',
}

function M.setup(config)
  if not config.default then
    error 'This config does not have a default key.'
  end
  user_config = config
end

function M.print_config()
  print(vim.inspect(user_config))
end

local function correct_position(line_to_cursor, linenr)
  local col = vim.fn.match(line_to_cursor, '\\s*\\k*$')
  return linenr - 1, col - 1
end

local function node_type_at_cursor(l, c)
  local root = tsutils.get_root_for_position(l, c)
  if not root then
    return
  end

  local node = root:named_descendant_for_range(l, c, l, c)
  if not node then
    return
  end

  return node:type()
end

local function get_completion(ft, line_to_cursor, lnum, col)
  local l, c = correct_position(line_to_cursor, lnum)
  local ft_completion = user_config[ft] or user_config.default
  if ft_completion then
    if type(ft_completion) == 'table' then
      local root = tsutils.get_root_for_position(l, c)
      -- Before attempting to match the node type, try query based filters
      for q, sub in pairs(ft_completion) do
        -- Queries always start with a parenthesis
        if vim.startswith(q, '(') then
          local query = vim.treesitter.parse_query(ft, q)
          for id, node in query:iter_captures(root, 0, l, l + 1) do
            local cname = query.captures[id]
            if tsutils.is_in_node_range(node, l, c) then
              if type(sub) == 'table' and sub[cname] then
                return sub[cname]
              elseif type(sub) == 'function' then
                return sub
              else
                -- We will definitely not be able to do anything with this source
                break
              end
            end
          end
        end
      end

      local t = node_type_at_cursor(l, c)
      if not t then
        return
      end
      local sub_completion = ft_completion[t] or ft_completion.default
      if sub_completion then
        return sub_completion
      end
    elseif type(ft_completion) == 'function' then
      return ft_completion
    end
  end
end

function M.complete()
  -- Only refresh when not restarting
  if vim.fn.pumvisible() == 0 then
    sources.invalidate_cache()
  end
  if not vim.fn.mode():find 'i' then
    return false
  end

  local bufnr = api.nvim_get_current_buf()
  local ft = api.nvim_buf_get_option(bufnr, 'filetype')

  local line = api.nvim_get_current_line()
  local lnum, cursor_pos = unpack(api.nvim_win_get_cursor(0))
  local line_to_cursor = line:sub(1, cursor_pos)
  local pref_start = line_to_cursor:find '%S*$'
  local prefix = line_to_cursor:sub(pref_start)

  -- The source signature is
  -- line_content, line_content_up_to_cursor, prefix, column

  local func = get_completion(ft, line_to_cursor, lnum, pref_start)
  if func then
    if func(line, line_to_cursor, prefix, pref_start) then
      return true
    end
  end
  return false
end

function M._CompleteDone()
  local completed_item = api.nvim_get_vvar 'completed_item'
  if not completed_item or not completed_item.user_data or not completed_item.user_data.source then
    return
  end
  local func = sources.complete_done_cbs[completed_item.user_data.source]
  if func then
    -- We will force the ignore of InsertLeave events for a certain time, in order to avoid strange
    -- behavior and flickering of the UI. So we _synchronously_ set 'eventignore' to ignore
    -- InsertLeave, and schedule the reset in the loop.
    --
    -- The reset is scheduled during this time, so that when the user's events start to be
    -- processed, everything will be just as if nothing happened.
    local previous_opt = api.nvim_get_option 'eventignore'
    local newval = previous_opt
    if #newval == 0 then
      newval = 'InsertLeave'
    else
      newval = 'InsertLeave,' .. newval
    end
    api.nvim_set_option('eventignore', newval)
    func(completed_item)
    vim.schedule(function()
      api.nvim_set_option('eventignore', previous_opt)
    end)
  end
end

function M._InsertCharPre()
  if vim.fn.pumvisible() == 1 then
    local char = api.nvim_get_vvar 'char'
    if char:find '%s' then
      -- Whitespace, so accept this choice and stop here
      utils.feed '<C-Y>'
    else
      -- Refresh completion after this char is inserted
      vim.schedule(function()
        M.complete()
      end)
    end
  end
end

return M
