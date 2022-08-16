
local record TSLocals
  record LocalCapture
    record Captured
      node: vim.treesitter.TSNode
    end
    var: Captured|nil
    ['function']: Captured|nil
    associated: Captured|nil
    parameter: Captured|nil
  end

  get_definitions: function(integer): {LocalCapture}
  iter_scope_tree: function(vim.treesitter.TSNode, integer|nil): {vim.treesitter.TSNode}
end

return TSLocals
