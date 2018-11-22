" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#source_code_model#go_to_definition#run()
" Description:  Jumps to the definition of a symbol under the cursor.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#source_code_model#go_to_definition#run(filename, line, col)
    if g:cxxd_src_code_model['started'] && g:cxxd_src_code_model['services']['go_to_definition']['enabled']
        " If buffer contents are modified but not saved, we need to serialize contents of the current buffer into temporary file.
        let l:contents_filename = a:filename
        if cxxd#utils#is_more_modifications_done(winnr())
            let l:contents_filename = '/tmp/tmp_' . fnamemodify(a:filename, ':p:t')
            call cxxd#utils#serialize_current_buffer_contents(l:contents_filename)
        endif
        python cxxd.api.source_code_model_go_to_definition_request(server_handle, vim.eval('a:filename'), vim.eval('l:contents_filename'), vim.eval('a:line'), vim.eval('a:col'))
    endif
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#source_code_model#go_to_definition#run_callback()
" Description:  Jumps to the definition found.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#source_code_model#go_to_definition#run_callback(status, filename, line, column)
    if a:status == v:true
        if a:filename != ''
            if expand('%:p') != a:filename
                execute('edit ' . a:filename)
            endif
            call cursor(a:line, a:column)
        else
            echohl WarningMsg | echom 'No definition found!' | echohl None
        endif
    else
        echohl WarningMsg | echomsg 'Something went wrong with source-code-model (go-to-definition) service. See Cxxd server log for more details!' | echohl None
    endif
endfunction
