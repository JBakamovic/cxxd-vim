" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#source_code_model#start()
" Description:  Starts the source-code-model service.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#source_code_model#start()
    let l:req = {'header': 0xF1, 'service_id': 0x0, 'payload': []}
    call cxxd#server#send_request(l:req)
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#source_code_model#start_callback()
" Description:  Service started.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#source_code_model#start_callback(status)
    if a:status == v:true
        let g:cxxd_src_code_model['started'] = 1
    else
        echohl WarningMsg | echomsg 'Something went wrong with source-code-model service start-up. See Cxxd server log for more details!' | echohl None
    endif
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#source_code_model#stop()
" Description:  Stops the source-code-model service.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#source_code_model#stop(subscribe_for_shutdown_callback)
    let l:req = {'header': 0xFE, 'service_id': 0x0, 'payload': [a:subscribe_for_shutdown_callback]}
    call cxxd#server#send_request(l:req)
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#source_code_model#stop_callback()
" Description:  Callback from cxxd#services#source_code_model#stop.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#source_code_model#stop_callback(status)
    if a:status == v:true
        let g:cxxd_src_code_model['started'] = 0
    else
        echohl WarningMsg | echomsg 'Something went wrong with source-code-model service shut-down. See Cxxd server log for more details!' | echohl None
    endif
endfunction

