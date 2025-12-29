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
        " Go To Include Request: [0x5, filename, contents_filename, line]
        let l:service_payload = [0x5, a:filename, l:contents_filename, a:line]
        let l:req = {'header': 0xF2, 'service_id': 0x0, 'payload': l:service_payload}
        call cxxd#server#send_request(l:req)
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
