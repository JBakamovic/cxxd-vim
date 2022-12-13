" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#source_code_model#start()
" Description:  Starts the source code model background service.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#source_code_model#start()
    " Enable balloon expressions if TypeDeduction service is enabled.
    if g:cxxd_src_code_model['services']['type_deduction']['enabled']
        set ballooneval balloonexpr=cxxd#services#source_code_model#type_deduction#run()
    endif
    python3 cxxd.api.source_code_model_start(server_handle)
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#source_code_model#start_callback()
" Description:  Callback from cxxd#services#source_code_model#start.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#source_code_model#start_callback(status)
    if a:status == v:true
        let g:cxxd_src_code_model['started'] = 1
        call cxxd#services#source_code_model#indexer#run_on_directory()
    else
        echohl WarningMsg | echomsg 'Something went wrong with source-code-model service start-up. See Cxxd server log for more details!' | echohl None
    endif
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#source_code_model#stop()
" Description:  Stops the source code model background service.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#source_code_model#stop(subscribe_for_shutdown_callback)
    python3 cxxd.api.source_code_model_stop(server_handle, vim.eval('a:subscribe_for_shutdown_callback'))
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

