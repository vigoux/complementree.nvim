local LspOptions = {}



local LuasnipOptions = {}




local CtagsOptions = {}



local FilepathOptions = {}








local TreesitterOptions = {}



local Sources = {}










local utils = require('complementree.utils')
local options = require('complementree.options')
local api = vim.api
local lsp = vim.lsp

local cache = {}

function Sources.invalidate_cache()
   cache = {}
end

local function cached(kind, func)
   return function(ltc, lnum)
      local m
      local p
      if not cache[kind] then
         m, p = func(ltc, lnum)
         cache[kind] = { m, p }
      else
         m = cache[kind][1]
         p = cache[kind][2]




         local pref_start = vim.fn.match(ltc, p .. '\\k*$') + 1
         if pref_start >= 1 then
            p = ltc:sub(pref_start)
         end
      end
      local new = {}
      for _, v in ipairs(m) do
         table.insert(new, v)
      end
      return new, p
   end
end





function Sources.luasnip_matches(opts)
   opts = options.get({
      exclude_defaults = false,
      filetype = nil,
   }, opts)

   local lsnip_present, luasnip = pcall(require, "luasnip")
   if not lsnip_present then
      error("LuaSnip is not installed")
   end

   local function add_snippet(items, s)
      table.insert(items, {
         word = s.trigger,
         kind = 'S',
         menu = table.concat(s.description or {}),
         icase = 1,
         dup = 1,
         empty = 1,
         equal = 1,
         user_data = { source = 'luasnip' },
      })
   end

   return cached('luasnip', function(line_to_cursor, _)
      local prefix = utils.prefix.lua_regex('%w*$', line_to_cursor)
      local items = {}










      for ftname, snips in pairs(luasnip.available()) do
         if not (ftname == 'all' and opts.exclude_defaults) then
            vim.tbl_map(function(s)
               add_snippet(items, s)
            end, snips)
         end
      end

      return items, prefix
   end)
end

local LspExtraInfo = {}





function Sources.lsp_matches(opts)
   opts = options.get({}, opts)
   return cached('lsp', function(line_to_cursor, lnum)


      local function adjust_start_col(line_number, line, items, encoding)
         local min_start_char = nil

         for _, item in ipairs(items) do
            if item.textEdit and item.textEdit.range.start.line == line_number - 1 then
               if min_start_char and min_start_char ~= item.textEdit.range.start.character then
                  return nil
               end
               min_start_char = item.textEdit.range.start.character
            end
         end
         if min_start_char then
            if encoding == 'utf-8' then
               return min_start_char + 1
            else
               return vim.str_byteindex(line, min_start_char, encoding == 'utf-16') + 1
            end
         else
            return nil
         end
      end

      local params = lsp.util.make_position_params()
      local result_all, err = lsp.buf_request_sync(0, 'textDocument/completion', params)
      if err then
         api.nvim_err_writeln(string.format('Error while completing lsp: %s', err))
         return {}, ''
      end
      if not result_all then
         return {}, ''
      end

      local matches = {}
      local start_col = vim.fn.match(line_to_cursor, '\\k*$') + 1
      for client_id, result in pairs(result_all) do
         local client = lsp.get_client_by_id(client_id)
         local items = lsp.util.extract_completion_items(result.result) or {}

         local tmp_col = adjust_start_col(lnum, line_to_cursor, items, client.offset_encoding or 'utf-16')
         if tmp_col and tmp_col < start_col then
            start_col = tmp_col
         end

         for _, item in ipairs(items) do
            local kind = lsp.protocol.CompletionItemKind[item.kind] or ''
            local word = nil
            if kind == 'Snippet' then
               word = item.label
            elseif item.insertTextFormat == 2 then
               if item.textEdit then
                  word = item.insertText or item.textEdit.newText
               elseif item.insertText then
                  if #item.label < #item.insertText then
                     word = item.label
                  else
                     word = item.insertText
                  end
               else
                  word = item.label
               end
            else
               word = (item.textEdit and item.textEdit.newText) or item.insertText or item.label
            end
            local ud = {
               source = 'lsp',
               extra = { client_id = client_id, item = item },
            }
            table.insert(matches, {
               word = word,
               abbr = item.label,
               kind = kind,
               menu = item.detail or '',
               icase = 1,
               dup = 1,
               empty = 1,
               equal = 1,
               user_data = ud,
            })
         end
      end
      local prefix = line_to_cursor:sub(start_col)
      return matches, prefix
   end)
end

local function apply_snippet(item, suffix, lnum)
   local luasnip = require('luasnip')
   if item.textEdit then
      luasnip.lsp_expand(item.textEdit.newText .. suffix)
   elseif item.insertText then
      luasnip.lsp_expand(item.insertText .. suffix)
   elseif item.label then
      luasnip.lsp_expand(item.label .. suffix)
   end
   vim.schedule(function()
      local curline = api.nvim_get_current_line()
      if vim.endswith(curline, suffix) and not luasnip.get_active_snip() then
         local newcol = #curline - #suffix
         api.nvim_win_set_cursor(0, { lnum + 1, newcol })
      end
   end)
end

local ctags_extension = {
   default = {
      ['c'] = 'class',
      ['d'] = 'define',
      ['e'] = 'enumerator',
      ['f'] = 'function',
      ['F'] = 'file',
      ['g'] = 'enumeration',
      ['m'] = 'member',
      ['p'] = 'prototype',
      ['s'] = 'structure',
      ['t'] = 'typedef',
      ['u'] = 'union',
      ['v'] = 'variable',
   },
}

function Sources.ctags_matches(opts)
   opts = options.get({}, opts)
   return cached('ctags', function(line_to_cursor, _)
      local prefix = utils.prefix.vim_keyword(line_to_cursor)

      local filetype = api.nvim_buf_get_option(0, 'filetype')
      local extensions = ctags_extension[filetype] or ctags_extension.default
      local tags = vim.fn.taglist('.*')

      local items = {}
      for _, t in ipairs(tags) do
         local ud = { source = 'ctags' }
         items[#items + 1] = {
            word = t.name,
            kind = (t.kind and extensions[t.kind] or 'undefined'),
            icase = 1,
            dup = 0,
            equal = 1,
            empty = 1,
            user_data = ud,
         }
      end

      return items, prefix
   end)
end



local os_name = string.lower(jit.os)
local is_linux = (os_name == 'linux' or os_name == 'osx' or os_name == 'bsd')
local os_sep = is_linux and '/' or '\\'
local os_path = '[' .. os_sep .. '%w+%-%.%_]*$'

function Sources.filepath_matches(opts)
   local relpath = utils.make_relative_path
   local config = options.get({
      show_hidden = false,
      ignore_directories = true,
      max_depth = math.huge,
      relative_paths = false,
      ignore_pattern = '',
      root_dirs = { '.' },
   }, opts)

   local function iter_files()
      local path_stack = vim.fn.reverse(config.root_dirs or { '.' })
      local iter_stack = {}
      for _, p in ipairs(path_stack) do
         table.insert(iter_stack, vim.loop.fs_scandir(p))
      end

      if config.max_depth == 0 then
         return function()
            return nil
         end
      end

      return function()
         local iter = iter_stack[#iter_stack]
         local path = path_stack[#path_stack]
         while true do
            local next_path, path_type = vim.loop.fs_scandir_next(iter)

            if not next_path then
               table.remove(iter_stack)
               table.remove(path_stack)
               if #iter_stack == 0 then
                  return nil
               end
               iter = iter_stack[#iter_stack]
               path = path_stack[#path_stack]
            elseif
(vim.startswith(next_path, '.') and not config.show_hidden) or
               (#config.ignore_pattern > 0 and string.find(next_path, config.ignore_pattern) ~= nil) then

               next_path = nil
               path_type = nil
            else
               local full_path = path .. os_sep .. next_path
               if path_type == 'directory' then
                  if #iter_stack < config.max_depth then
                     iter = vim.loop.fs_scandir(full_path)
                     path = full_path
                     table.insert(path_stack, full_path)
                     table.insert(iter_stack, iter)
                  end
                  if not config.ignore_directories then
                     return full_path
                  end
               else
                  return full_path
               end
            end
         end
      end
   end

   return cached('filepath', function(line_to_cursor, _)
      local prefix = utils.prefix.lua_regex(os_path, line_to_cursor)

      local cwd = vim.fn.getcwd()
      local fpath
      local matches = {}
      for path in iter_files() do
         fpath = config.relative_paths and relpath(path, cwd) or path

         matches[#matches + 1] = {
            word = fpath,
            abbr = fpath,
            kind = '[path]',
            icase = 1,
            dup = 1,
            empty = 1,
            equal = 1,
            user_data = { source = 'filepath' },
         }
      end

      return matches, prefix
   end)
end



local tslocals = require('nvim-treesitter.locals')

function Sources.treesitter_matches(opts)
   local _config = options.get({}, opts)

   return cached('treesitter', function(line_to_cursor, _lnum)
      local prefix = utils.prefix.lua_regex('%S*$', line_to_cursor)
      local defs = tslocals.get_definitions(0)

      local items = {}

      for _, def in ipairs(defs) do

         local node
         local kind
         for k, cap in pairs(def) do
            if k ~= 'associated' then
               node = cap.node
               kind = k
               break
            end
         end

         if node then
            items[#items + 1] = {
               word = vim.treesitter.query.get_node_text(node, 0),
               kind = kind,
               icase = 1,
               dup = 0,
               empty = 1,
               equal = 1,
               user_data = { source = 'treesitter' },
            }
         end
      end

      return items, prefix
   end)
end



local function lsp_completedone(completed_item)
   local cursor = api.nvim_win_get_cursor(0)
   local col = cursor[2]
   local lnum = cursor[1] - 1
   local item = completed_item.user_data
   local bufnr = api.nvim_get_current_buf()
   local expand_snippet = item.insertTextFormat == 2

   local client = lsp.get_client_by_id()
   if not client then
      return
   end

   local resolveEdits = (client.server_capabilities.completionProvider or {}).resolveProvider
   local offset_encoding = client and client.offset_encoding or 'utf-16'

   local tidy = function() end
   local suffix = nil
   if expand_snippet then
      local line = api.nvim_buf_get_lines(bufnr, lnum, lnum + 1, true)[1]
      tidy = function()

         local start_char = col - #completed_item.word
         local l = line
         api.nvim_buf_set_text(bufnr, lnum, start_char, lnum, #l, { '' })
      end
      suffix = line:sub(col + 1)
   end

   if item.additionalTextEdits then
      tidy()
      lsp.util.apply_text_edits(item.additionalTextEdits, bufnr, offset_encoding)
      if expand_snippet then
         apply_snippet(item, suffix, lnum)
      end
   elseif resolveEdits and type(item) == 'table' then
      local v = client.request_sync('completionItem/resolve', item, 1000, bufnr)
      assert(not v.err, vim.inspect(v.err))
      local res = v.result
      if res.additionalTextEdits then
         tidy()
         tidy = function() end
         lsp.util.apply_text_edits(res.additionalTextEdits, bufnr, offset_encoding)
      end
      if expand_snippet then
         tidy()
         apply_snippet(item, suffix, lnum)
      end
   elseif expand_snippet then
      tidy()
      apply_snippet(item, suffix, lnum)
   end
end

local function luasnip_completedone(_)
   if require('luasnip').expandable() then
      require('luasnip').expand()
   end
end

Sources.complete_done_cbs = {
   lsp = lsp_completedone,
   luasnip = luasnip_completedone,
}

return Sources
