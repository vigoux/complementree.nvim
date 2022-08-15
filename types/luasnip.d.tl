local record Luasnip
  record Snippet
    description: {string}
    name: string
    regTrig: boolean
    trigger: string
    wordTrig: boolean
  end

  available: function(): {string: {Snippet}}
  expandable: function(): boolean
  expand: function()
  lsp_expand: function(string)
  get_active_snip: function(): Snippet
end

return Luasnip
