" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#clang_format#start()
" Description:  Starts the source code formatting background service.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#clang_format#start()
    let l:req = {'header': 0xF1, 'service_id': 0x2, 'payload': []}
    call cxxd#server#send_request(l:req)
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#clang_format#start_callback()
" Description:  Callback from cxxd#services#clang_format#start.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#clang_format#start_callback(status)
    if a:status == v:true
        let g:cxxd_clang_format['started'] = 1
    else
        echohl WarningMsg | echomsg 'Something went wrong with clang-format service start-up. See Cxxd server log for more details!' | echohl None
    endif
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#clang_format#stop()
" Description:  Stops the source code formatting background service.
" Dependency:
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#clang_format#stop(subscribe_for_shutdown_callback)
    let l:req = {'header': 0xFE, 'service_id': 0x2, 'payload': [a:subscribe_for_shutdown_callback]}
    call cxxd#server#send_request(l:req)
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#clang_format#stop_callback()
" Description:  Callback from cxxd#services#clang_format#stop.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#clang_format#stop_callback(status)
    if a:status == v:true
        let g:cxxd_clang_format['started'] = 0
    else
        echohl WarningMsg | echomsg 'Something went wrong with clang-format service shut-down. See Cxxd server log for more details!' | echohl None
    endif
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#clang_format#run()
" Description:  Triggers the formatting on current buffer.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#clang_format#run(filename)
    if g:cxxd_clang_format['started'] && g:cxxd_clang_format['enabled']
        " Request: [filename]
        " Service ID: 0x2 (ClangFormat)
        let l:service_payload = [a:filename]
        let l:req = {'header': 0xF2, 'service_id': 0x2, 'payload': l:service_payload}
        call cxxd#server#send_request(l:req)
    endif
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#clang_format#run_callback()
" Description:  Reload the buffer if we are still on the same one.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#clang_format#run_callback(status, filename)
    if a:status == v:true
        " TODO Ideally, re-indexing logic shall not be client's code (frontend) responsibility. We need to enable communication
        " between components on Cxxd server level.
        call cxxd#services#source_code_model#indexer#run_on_single_file(a:filename)
        let l:current_buffer = expand('%:p')
        if l:current_buffer == a:filename
            execute('e')
            execute('checktime')
        endif
    else
        echohl WarningMsg | echomsg 'Something went wrong with clang-format service. See Cxxd server log for more details!' | echohl None
    endif
endfunction
