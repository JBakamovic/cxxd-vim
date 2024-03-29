let s:show_include_in_preview_window = v:false

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#source_code_model#go_to_include#run()
" Description:  Fetches the filename which include directive corresponds to on the given (current) line.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#source_code_model#go_to_include#run(filename, line, show_include_in_preview_window)
    if g:cxxd_src_code_model['started'] && g:cxxd_src_code_model['services']['go_to_include']['enabled']
        let s:show_include_in_preview_window = a:show_include_in_preview_window
        " If buffer contents are modified but not saved, we need to serialize contents of the current buffer into temporary file.
        let l:contents_filename = cxxd#utils#pick_content_filename(a:filename)
        if cxxd#utils#is_more_modifications_done(winnr())
            call cxxd#utils#serialize_current_buffer_contents(l:contents_filename)
        endif
        python3 cxxd.api.source_code_model_go_to_include_request(
\           server_handle,
\           vim.eval('a:filename'),
\           vim.eval('l:contents_filename'),
\           vim.eval('a:line')
\       )
    endif
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#source_code_model#go_to_include#run_callback()
" Description:  Opens the filename which corresponds to the include directive.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#source_code_model#go_to_include#run_callback(status, filename)
    if a:status == v:true
        if a:filename != ''
            if s:show_include_in_preview_window
                call cxxd#utils#preview_open(a:filename, 1, 1)
            else
                execute('edit ' . a:filename)
            endif
        else
            echohl WarningMsg | echom 'No corresponding include file found!' | echohl None
        endif
    else
        echohl WarningMsg | echomsg 'Something went wrong with source-code-model (go-to-include) service. See Cxxd server log for more details!' | echohl None
    endif
endfunction
