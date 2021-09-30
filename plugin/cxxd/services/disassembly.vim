" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#disassembly#start()
" Description:  Starts the disassembly background service.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#disassembly#start()
    if g:cxxd_disassembly['enabled']
        python3 cxxd.api.disassembly_start(server_handle)
    endif
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#disassembly#start_callback()
" Description:  Callback from cxxd#services#disassembly#start.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#disassembly#start_callback(status)
    if a:status == v:true
        let g:cxxd_disassembly['started'] = 1
    else
        echohl WarningMsg | echomsg 'Something went wrong with disassembly service start-up. See Cxxd server log for more details!' | echohl None
    endif
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#disassembly#stop()
" Description:  Stops the disassembly background service.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#disassembly#stop(subscribe_for_shutdown_callback)
    if g:cxxd_disassembly['enabled']
        python3 cxxd.api.disassembly_stop(server_handle, vim.eval('a:subscribe_for_shutdown_callback'))
    endif
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#disassembly#stop_callback()
" Description:  Callback from cxxd#services#disassembly#stop.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#disassembly#stop_callback(status)
    if a:status == v:true
        let g:cxxd_disassembly['started'] = 0
    else
        echohl WarningMsg | echomsg 'Something went wrong with disassembly service shut-down. See Cxxd server log for more details!' | echohl None
    endif
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#disassembly#run()
" Description:  Triggers the disassembly for given filename.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#disassembly#run(filename, line)
    if g:cxxd_disassembly['started'] && g:cxxd_disassembly['enabled']
        python3 cxxd.api.disassembly_request_run(server_handle, vim.eval('a:filename'), vim.eval('a:line'))
    endif
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#disassembly#run_callback()
" Description:  Display the results of disassembly.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#disassembly#run_callback(status, filename, disassembly_output)
    if a:status == v:true
        execute('vs' . a:disassembly_output)
        execute('set ft=' . 'gas')
        execute('set syn=' . 'gas')
    else
        echohl WarningMsg | echomsg 'Something went wrong with disassembly service. See Cxxd server log for more details!' | echohl None
    endif
endfunction


