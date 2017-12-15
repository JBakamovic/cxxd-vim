" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#source_code_model#diagnostics#run()
" Description:  Triggers the source code diagnostics for current buffer.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#source_code_model#diagnostics#run(filename)
    if g:cxxd_src_code_model['services']['diagnostics']['enabled']
        " If buffer contents are modified but not saved, we need to serialize contents of the current buffer into temporary file.
        let l:contents_filename = a:filename
        if getbufvar(a:filename, '&modified')
            let l:contents_filename = '/tmp/tmp_' . fnamemodify(a:filename, ':p:t')
            call cxxd#utils#serialize_current_buffer_contents(l:contents_filename)
        endif
        python cxxd.api.source_code_model_diagnostics_request(server_handle, vim.eval('a:filename'), vim.eval('l:contents_filename'))
    endif
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#source_code_model#diagnostics#run_callback()
" Description:  Populates the quickfix window with source code diagnostics.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#source_code_model#diagnostics#run_callback(status, diagnostics)
    if a:status == v:true
        call setloclist(0, a:diagnostics, 'r')
        redraw
    else
        echohl WarningMsg | echomsg 'Something went wrong with source-code-model (diagnostics) service. See Cxxd server log for more details!' | echohl None
    endif       
endfunction
