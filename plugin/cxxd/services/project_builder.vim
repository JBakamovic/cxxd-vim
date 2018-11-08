" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     services#project_builder#start()
" Description:  Starts the project builder background service.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#project_builder#start()
    python cxxd.api.project_builder_start(server_handle)
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#project_builder#start_callback()
" Description:  Callback from services#project_builder#start.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#project_builder#start_callback(status)
    if a:status == v:true
        let g:cxxd_project_builder['started'] = 1
    else
        echohl WarningMsg | echomsg 'Something went wrong with project-builder service start-up. See Cxxd server log for more details!' | echohl None
    endif
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#project_builder#stop()
" Description:  Stops the project builder background service.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#project_builder#stop(subscribe_for_shutdown_callback)
    python cxxd.api.project_builder_stop(server_handle, vim.eval('a:subscribe_for_shutdown_callback'))
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#project_builder#stop_callback()
" Description:  Callback from services#project_builder#stop.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#project_builder#stop_callback(status)
    if a:status == v:true
        let g:cxxd_project_builder['started'] = 0
    else
        echohl WarningMsg | echomsg 'Something went wrong with project-builder service shut-down. See Cxxd server log for more details!' | echohl None
    endif
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#project_builder#run()
" Description:  Triggers the build for current project.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#project_builder#run(build_command, ...)
    if g:cxxd_project_builder['started']
        let l:additional_args = ''
        if a:0 != 0
            let l:additional_args = a:1
            let i = 2
            while i <= a:0
                execute "let l:additional_args = l:additional_args . \" \" . a:" . i
                let i = i + 1
            endwhile
        endif
        call setqflist([])
        python cxxd.api.project_builder_request(server_handle, vim.eval('a:build_command') + ' ' + vim.eval('l:additional_args'))
    endif
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#project_builder#run_callback()
" Description:  Callback from services#project_builder#run.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#project_builder#run_callback(status, duration, build_process_exit_code, build_output)
    if a:status == v:true
        echomsg 'Build process took ' . a:duration ". ' with exit code ' . a:build_process_exit_code
        execute('cgetfile ' . a:build_output)
        execute('copen')
        redraw
    else
        echohl WarningMsg | echomsg 'Something went wrong with project-builder service. See Cxxd server log for more details!' | echohl None
    endif
endfunction

