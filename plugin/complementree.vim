" Last Change: 2021 Dec 11

imap <Plug>(complementree-complete) <cmd>lua require"complementree".complete()<CR>
autocmd CompleteDone * lua require'complementree'._CompleteDone()
autocmd InsertCharPre * lua require'complementree'._InsertCharPre()
