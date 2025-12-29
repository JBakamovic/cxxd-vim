" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#clang_tidy#start()
" Description:  Starts the clang-tidy background service.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#clang_tidy#start()
    let l:req = {'header': 0xF1, 'service_id': 0x3, 'payload': []}
    call cxxd#server#send_request(l:req)
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#clang_tidy#start_callback()
" Description:  Callback from cxxd#services#clang_tidy#start.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#clang_tidy#start_callback(status)
    if a:status == v:true
        let g:cxxd_clang_tidy['started'] = 1
    else
        echohl WarningMsg | echomsg 'Something went wrong with clang-tidy service start-up. See Cxxd server log for more details!' | echohl None
    endif
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#clang_tidy#stop()
" Description:  Stops the clang-tidy background service.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#clang_tidy#stop(subscribe_for_shutdown_callback)
    let l:req = {'header': 0xFE, 'service_id': 0x3, 'payload': [a:subscribe_for_shutdown_callback]}
    call cxxd#server#send_request(l:req)
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#clang_tidy#stop_callback()
" Description:  Callback from cxxd#services#clang_tidy#stop.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#clang_tidy#stop_callback(status)
    if a:status == v:true
        let g:cxxd_clang_tidy['started'] = 0
    else
        echohl WarningMsg | echomsg 'Something went wrong with clang-tidy service shut-down. See Cxxd server log for more details!' | echohl None
    endif
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#clang_tidy#run()
" Description:  Triggers the clang-tidy for given filename and (optionally) applies the fixes.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#clang_tidy#run(filename, apply_fixes)
    if g:cxxd_clang_tidy['started'] && g:cxxd_clang_tidy['enabled']
        " Request: [filename, apply_fixes]
        " Service ID: 0x3 (ClangTidy)
        let l:service_payload = [a:filename, a:apply_fixes]
        let l:req = {'header': 0xF2, 'service_id': 0x3, 'payload': l:service_payload}
        call cxxd#server#send_request(l:req)
    endif
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#clang_tidy#run_callback()
" Description:  Display the results of clang-tidy.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#clang_tidy#run_callback(status, filename, fixes_applied, clang_tidy_output)
    if a:status == v:true
        if a:fixes_applied
            " TODO Ideally, re-indexing logic shall not be client's code (frontend) responsibility. We need to enable communication
            " between components on Cxxd server level.
            call cxxd#services#source_code_model#indexer#run_on_single_file(a:filename)
        endif
        execute('cgetfile ' . a:clang_tidy_output)
        execute('copen')
        redraw
    else
        echohl WarningMsg | echomsg 'Something went wrong with clang-tidy service. See Cxxd server log for more details!' | echohl None
    endif
endfunction

