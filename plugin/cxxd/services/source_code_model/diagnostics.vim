" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#source_code_model#diagnostics#run()
" Description:  Triggers the source code diagnostics for current buffer.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#source_code_model#diagnostics#run(filename)
    if g:cxxd_src_code_model['started'] && g:cxxd_src_code_model['services']['diagnostics']['enabled']
        " If buffer contents are modified but not saved, we need to serialize contents of the current buffer into temporary file.
        let l:contents_filename = cxxd#utils#pick_content_filename(a:filename)
        if cxxd#utils#is_more_modifications_done(winnr())
            echomsg 'Serializing buffer contents from DIAGNOSTICS.'
            call cxxd#utils#serialize_current_buffer_contents(l:contents_filename)
        endif

        let l:winnr = winnr()
        if getloclist(l:winnr) == []
            python cxxd.api.source_code_model_diagnostics_request(server_handle, vim.eval('a:filename'), vim.eval('l:contents_filename'))
        elseif getloclist(l:winnr)[0].bufnr != winbufnr(l:winnr)
            python cxxd.api.source_code_model_diagnostics_request(server_handle, vim.eval('a:filename'), vim.eval('l:contents_filename'))
        elseif cxxd#utils#is_more_modifications_done(l:winnr)
            python cxxd.api.source_code_model_diagnostics_request(server_handle, vim.eval('a:filename'), vim.eval('l:contents_filename'))
        endif
    endif
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#source_code_model#diagnostics#run_callback()
" Description:  Populates the quickfix window with source code diagnostics.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#source_code_model#diagnostics#run_callback(status, diagnostics)
    let l:winnr = winnr()
    call setloclist(l:winnr, [{'bufnr' : winbufnr(l:winnr), 'text' : 'Clang diagnostics'}], 'r')
    if a:status == v:true
        call setloclist(l:winnr, a:diagnostics, 'a')
        redraw
    else
        echohl WarningMsg | echomsg 'Something went wrong with source-code-model (diagnostics) service. See Cxxd server log for more details!' | echohl None
    endif       
endfunction
