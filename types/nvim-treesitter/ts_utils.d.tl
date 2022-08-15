local record TSUtils
  get_root_for_position: function(integer, integer, vim.treesitter.TSTree|nil): vim.treesitter.TSNode
  is_in_node_range: function(vim.treesitter.TSNode, integer, integer): boolean
end

return TSUtils
