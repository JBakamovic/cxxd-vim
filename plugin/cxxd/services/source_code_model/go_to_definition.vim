let s:show_definition_in_preview_window = v:false

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#source_code_model#go_to_definition#run()
" Description:  Jumps to the definition of a symbol under the cursor.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#source_code_model#go_to_definition#run(filename, line, col, show_definition_in_preview_window)
    if g:cxxd_src_code_model['started'] && g:cxxd_src_code_model['services']['go_to_definition']['enabled']
        let s:show_definition_in_preview_window = a:show_definition_in_preview_window
        " If buffer contents are modified but not saved, we need to serialize contents of the current buffer into temporary file.
        let l:contents_filename = cxxd#utils#pick_content_filename(a:filename)
        if cxxd#utils#is_more_modifications_done(winnr())
            "echomsg 'Serializing buffer contents from GO-TO-DEFINITION.'
            call cxxd#utils#serialize_current_buffer_contents(l:contents_filename)
        endif
        python3 cxxd.api.source_code_model_go_to_definition_request(
\           server_handle,
\           vim.eval('a:filename'),
\           vim.eval('l:contents_filename'),
\           vim.eval('a:line'),
\           vim.eval('a:col')
\       )
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
                if s:show_definition_in_preview_window
                    let l:preview_cmd = 'pedit +normal' . a:line . 'G' . a:column . '| ' . a:filename
                    execute(l:preview_cmd)
                else
                    execute('edit ' . a:filename)
                    call cursor(a:line, a:column)
                endif
            endif
        else
            echohl WarningMsg | echom 'No definition found!' | echohl None
        endif
    else
        echohl WarningMsg | echomsg 'Something went wrong with source-code-model (go-to-definition) service. See Cxxd server log for more details!' | echohl None
    endif
endfunction
