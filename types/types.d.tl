global record CompleteExtraInfo
  source: string
  extra: any
end

global record CompleteItem
  word: string
  abbr: string|nil
  menu: string|nil
  info: string|nil
  kind: string|nil
  icase: integer|nil
  equal: integer|nil
  dup: integer|nil
  empty: integer|nil
  user_data: CompleteExtraInfo
end

global type Source = function(string, integer): {CompleteItem}, string
global type Pipe = function(Source): Source
global type Completor = function(string, integer): boolean

global record vim
  record fn
    record Tag
      name: string
      filename: string
      cmd: string
      kind: string
      static: string
    end

    taglist: function(string, string|nil): {Tag}
    pumvisible: function(): integer
    match: function(string|{string}, string, integer, integer): integer
    mode: function(): string
    getcwd: function(): string
    complete: function(integer, {CompleteItem})
    reverse: function<T>({T}): {T}
  end

  record api
    nvim_feedkeys: function(string, string, boolean)
    nvim_err_writeln: function(string)
    nvim_get_current_buf: function(): integer
    nvim_get_current_line: function(): string
    nvim_replace_termcodes: function(string, boolean, boolean, boolean): string
    nvim_set_option: function(string, any)
    nvim_get_option: function(string): any
    nvim_get_vvar: function(string): any
    nvim_buf_get_option: function(integer, string): any
    nvim_buf_get_lines: function(integer, integer, integer, boolean): {string}
    nvim_buf_set_text: function(integer, integer, integer, integer, integer, {string})
    nvim_win_set_cursor: function(integer, {integer, integer})
    nvim_win_get_cursor: function(integer): {integer, integer}
  end

  record lsp

    record LspPosition
      line: integer
      character: integer
    end

    record LspRange
      start: LspPosition
      ["end"]: LspPosition
    end

    record LspTextEdit
      range: LspRange
      newText: string
    end

    record LspCompletionItem
      label: string
      detail: string|nil
      textEdit: LspTextEdit
      insertTextFormat: integer|nil
      insertText: string|nil
      additionalTextEdits: {LspTextEdit}
      kind: integer
    end

    record LspResult
      result: any
      err: string|nil
    end

    record LspClient
      request_sync: function(string, any, integer, integer): LspResult
      offset_encoding: string|nil
      record server_capabilities
        record completionProvider
          resolveProvider: boolean
        end
      end
    end


    record util
      apply_text_edits: function({LspTextEdit}, integer, string)
      make_position_params: function(): any
      extract_completion_items: function(any): {LspCompletionItem}
    end

    record protocol
      CompletionItemKind: {integer:string}
    end

    buf_request_sync: function(integer, string, any): {integer:LspResult}, string|nil
    get_client_by_id: function(integer): LspClient
  end

  record loop
    record FSIterator
    end
    fs_scandir: function(string): FSIterator
    fs_scandir_next: function(FSIterator): string|nil, string
  end

  record treesitter
    record TSTree
    end

    record TSNode
      named_descendant_for_range: function(TSNode, integer, integer, integer, integer): TSNode
      type: function(TSNode): string
    end

    record TSQuery
      captures: {integer: string}

      iter_captures: function(TSQuery, TSNode, integer, integer|nil, integer|nil, integer|nil, integer|nil): function(): integer, TSNode
    end

    parse_query: function(string, string): TSQuery
  end

  schedule: function(function())
  startswith: function(string, string): boolean
  endswith: function(string, string): boolean
  str_byteindex: function(string, integer, boolean|nil): integer

  tbl_deep_extend: function(string, ...: table): table
  tbl_map: function<T>(function(T), {T})

  list_extend: function<T>({T}, {T}, integer|nil, integer|nil): {T}
  inspect: function(...: any): string
end

global record jit
  os: string
end
