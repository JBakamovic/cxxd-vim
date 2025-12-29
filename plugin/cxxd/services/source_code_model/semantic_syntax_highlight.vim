" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#source_code_model#semantic_syntax_highlight#run()
" Description:  Triggers the source code highlighting for current buffer.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#source_code_model#semantic_syntax_highlight#run(filename)
    if g:cxxd_src_code_model['started'] && g:cxxd_src_code_model['services']['semantic_syntax_highlight']['enabled']
        " If buffer contents are modified but not saved, we need to serialize contents of the current buffer into temporary file.
        let l:contents_filename = cxxd#utils#pick_content_filename(a:filename)
        if cxxd#utils#is_more_modifications_done(winnr())
            call cxxd#utils#serialize_current_buffer_contents(l:contents_filename)
        endif

        " We don't want to fire semantic syntax highlighting request on each
        " CursorHold(I) event but only when viewport has been actually changed or
        " if there were some modifications being done.
        let l:current_visible_line_begin = line('w0')
        let l:current_visible_line_end = line('w$')
        if cxxd#utils#is_more_modifications_done(winnr()) || cxxd#utils#is_viewport_changed(winnr())
            " Semantic Syntax Highlight Request: [0x1, filename, contents_filename, start_line, end_line]
            let l:service_payload = [0x1, a:filename, l:contents_filename, l:current_visible_line_begin, l:current_visible_line_end]
            let l:req = {'header': 0xF2, 'service_id': 0x0, 'payload': l:service_payload}
            call cxxd#server#send_request(l:req)
        endif
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
            " Clear all previously added matches
            call clearmatches()

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

