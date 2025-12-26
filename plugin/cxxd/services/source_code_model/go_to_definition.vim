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
            call cxxd#utils#serialize_current_buffer_contents(l:contents_filename)
        endif
        
        " Construct Request
        " Header: SEND_SERVICE (0xF2)
        " Service ID: SOURCE_CODE_MODEL (0x0)
        " Payload: [GO_TO_DEFINITION (0x4), filename, content_filename, line, col]
        let l:service_payload = [0x4, a:filename, l:contents_filename, a:line, a:col]
        let l:req = {'header': 0xF2, 'service_id': 0, 'payload': l:service_payload}
        
        call cxxd#server#send_request(l:req)
    endif
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#source_code_model#go_to_definition#run_callback()
" Description:  Jumps to the definition found.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#source_code_model#go_to_definition#run_callback(status, filename, line, column)
    if a:status == v:true
        if a:filename != ''
            if s:show_definition_in_preview_window
                call cxxd#utils#preview_open(a:filename, a:line, a:column)
            else
                if expand('%p') != a:filename
                    execute('edit ' . a:filename)
                endif
                call cursor(a:line, a:column)
            endif
        else
            echohl WarningMsg | echom 'No definition found!' | echohl None
        endif
    else
        echohl WarningMsg | echomsg 'Something went wrong with source-code-model (go-to-definition) service. See Cxxd server log for more details!' | echohl None
    endif
endfunction
