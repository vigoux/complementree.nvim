" Last Change: 2021 Aug 20

imap <Plug>(complementree-complete) <cmd>lua require"complementree".complete()<CR>
autocmd CompleteDone * lua require'complementree.sources'._CompleteDone()
