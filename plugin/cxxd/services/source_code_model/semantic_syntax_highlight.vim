" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#source_code_model#semantic_syntax_highlight#run()
" Description:  Triggers the source code highlighting for current buffer.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#source_code_model#semantic_syntax_highlight#run(filename)
    if g:cxxd_src_code_model['services']['semantic_syntax_highlight']['enabled']
        " If buffer contents are modified but not saved, we need to serialize contents of the current buffer into temporary file.
        let l:contents_filename = a:filename
        if getbufvar(a:filename, '&modified')
            let l:contents_filename = '/tmp/tmp_' . fnamemodify(a:filename, ':p:t')
            call cxxd#utils#serialize_current_buffer_contents(l:contents_filename)
        endif
        python cxxd.api.source_code_model_semantic_syntax_highlight_request(server_handle, vim.eval('a:filename'), vim.eval('l:contents_filename'))
    endif
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#source_code_model#semantic_syntax_highlight#run_callback()
" Description:  Apply the results of source code highlighting for given filename.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#source_code_model#semantic_syntax_highlight#run_callback(status, filename, syntax_file)
    if a:status == v:true
        let l:current_buffer = expand('%:p')
        if l:current_buffer == a:filename
            " Apply the syntax highlighting rules
            execute('source ' . a:syntax_file)

            " Following command is a quick hack to apply the new syntax for
            " the given buffer. I haven't found any other more viable way to do it 
            " while keeping it fast & low on resources,
            execute(':redrawstatus')
        endif
    else
        echohl WarningMsg | echomsg 'Something went wrong with source-code-model (semantic-syntax-highlighting) service. See Cxxd server log for more details!' | echohl None
    endif
endfunction

