" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#clang_tidy#start()
" Description:  Starts the clang-tidy background service.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#clang_tidy#start()
    python3 cxxd.api.clang_tidy_start(server_handle)
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
    python3 cxxd.api.clang_tidy_stop(server_handle, vim.eval('a:subscribe_for_shutdown_callback'))
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
        python3 cxxd.api.clang_tidy_request(server_handle, vim.eval('a:filename'), vim.eval('a:apply_fixes'))
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

