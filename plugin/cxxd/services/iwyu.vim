" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#iwyu#start()
" Description:  Starts the iwyu background service.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#iwyu#start()
    python3 cxxd.api.iwyu_start(server_handle)
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#iwyu#start_callback()
" Description:  Callback from cxxd#services#iwyu#start.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#iwyu#start_callback(status)
    if a:status == v:true
        let g:cxxd_iwyu['started'] = 1
    else
        echohl WarningMsg | echomsg 'Something went wrong with iwyu service start-up. See Cxxd server log for more details!' | echohl None
    endif
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#iwyu#stop()
" Description:  Stops the iwyu background service.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#iwyu#stop(subscribe_for_shutdown_callback)
    python3 cxxd.api.iwyu_stop(server_handle, vim.eval('a:subscribe_for_shutdown_callback'))
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#iwyu#stop_callback()
" Description:  Callback from cxxd#services#iwyu#stop.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#iwyu#stop_callback(status)
    if a:status == v:true
        let g:cxxd_iwyu['started'] = 0
    else
        echohl WarningMsg | echomsg 'Something went wrong with iwyu service shut-down. See Cxxd server log for more details!' | echohl None
    endif
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#iwyu#run()
" Description:  Triggers the iwyu for given filename and (optionally) applies the fixes.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#iwyu#run(filename, apply_fixes)
    if g:cxxd_iwyu['started'] && g:cxxd_iwyu['enabled']
        if a:apply_fixes
            python3 cxxd.api.iwyu_request_run_and_apply_fixes(server_handle, vim.eval('a:filename'))
        else
            python3 cxxd.api.iwyu_request_run(server_handle, vim.eval('a:filename'))
        endif
    endif
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#iwyu#run_callback()
" Description:  Display the results of iwyu.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#iwyu#run_callback(status, filename, iwyu_output)
    if a:status == v:true
        execute('cgetfile ' . a:iwyu_output)
        execute('copen')
        redraw
    else
        echohl WarningMsg | echomsg 'Something went wrong with iwyu service. See Cxxd server log for more details!' | echohl None
    endif
endfunction

