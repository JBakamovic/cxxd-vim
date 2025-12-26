" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#source_code_model#diagnostics#run()
" Description:  Triggers the source code diagnostics for current buffer.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#source_code_model#diagnostics#run(filename)
    if g:cxxd_src_code_model['started'] && g:cxxd_src_code_model['services']['diagnostics']['enabled']
        " If buffer contents are modified but not saved, we need to serialize contents of the current buffer into temporary file.
        let l:contents_filename = cxxd#utils#pick_content_filename(a:filename)
        if cxxd#utils#is_more_modifications_done(winnr())
            call cxxd#utils#serialize_current_buffer_contents(l:contents_filename)
        endif

        let l:winnr = winnr()
        let l:should_fetch = v:false

        if !exists('b:cxxd_diagnostics_fetched')
            let l:should_fetch = v:true
            let b:cxxd_diagnostics_fetched = v:true
        endif

        if cxxd#utils#is_more_modifications_done(l:winnr)
            let l:should_fetch = v:true
        endif

        if getloclist(l:winnr) != [] && getloclist(l:winnr)[0].bufnr != winbufnr(l:winnr)
            let l:should_fetch = v:true
        endif

        if l:should_fetch
            " Reset the flags so we don't fetch again until next change
            call setwinvar(l:winnr, 'more_modifications_done', v:false)
            if exists('b:cxxd_diagnostics_fetched')
                 " If we are fetching because of modification, we just keep the flag true.
            endif

            let l:service_payload = [0x2, a:filename, l:contents_filename]
            let l:req = {'header': 0xF2, 'service_id': 0x0, 'payload': l:service_payload}
            call cxxd#server#send_request(l:req)
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
        if len(a:diagnostics)
            echohl WarningMsg | echomsg 'Some issues with the source code were found. For better experience, please inspect those in QuickFix window.' | echohl None
        else
            echohl MoreMsg | echomsg 'Kewl. No issues were found with the code.' | echohl None
        endif
        call setloclist(l:winnr, a:diagnostics, 'a')
    else
        echohl WarningMsg | echomsg 'Something went wrong with source-code-model (diagnostics) service. See Cxxd server log for more details!' | echohl None
    endif
endfunction
