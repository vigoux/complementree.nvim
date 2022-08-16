local record TSUtils
  get_node_at_cursor: function(integer|nil, boolean|nil): vim.treesitter.TSNode
  get_root_for_position: function(integer, integer, vim.treesitter.TSTree|nil): vim.treesitter.TSNode
  is_in_node_range: function(vim.treesitter.TSNode, integer, integer): boolean
end

return TSUtils
