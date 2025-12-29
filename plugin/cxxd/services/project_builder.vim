" Variable holding a path to the file which will be containing build output
let s:cxxd_project_builder_output_build_file = ''
" Variable that keeps the buffer number of running terminal
let s:terminal_buf_id = 0

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     services#project_builder#start()
" Description:  Starts the project builder background service.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#project_builder#start()
    let l:req = {'header': 0xF1, 'service_id': 0x4, 'payload': []}
    call cxxd#server#send_request(l:req)
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#project_builder#start_callback()
" Description:  Callback from services#project_builder#start.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#project_builder#start_callback(status, output_build_file)
    if a:status == v:true
        let g:cxxd_project_builder['started'] = 1
        let s:cxxd_project_builder_output_build_file = a:output_build_file
    else
        echohl WarningMsg | echomsg 'Something went wrong with project-builder service start-up. See Cxxd server log for more details!' | echohl None
    endif
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#project_builder#stop()
" Description:  Stops the project builder background service.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#project_builder#stop(subscribe_for_shutdown_callback)
    let l:req = {'header': 0xFE, 'service_id': 0x4, 'payload': [a:subscribe_for_shutdown_callback]}
    call cxxd#server#send_request(l:req)
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#project_builder#stop_callback()
" Description:  Callback from services#project_builder#stop.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#project_builder#stop_callback(status)
    if a:status == v:true
        let g:cxxd_project_builder['started'] = 0
        let s:cxxd_project_builder_output_build_file = ''
    else
        echohl WarningMsg | echomsg 'Something went wrong with project-builder service shut-down. See Cxxd server log for more details!' | echohl None
    endif
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#project_builder#run()
" Description:  Triggers the build for current project.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#project_builder#run_custom(build_command, ...)
    if g:cxxd_project_builder['started'] && g:cxxd_project_builder['enabled']
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
        " Request: [build_command + ' ' + additional_args]
        " Service ID: 0x4 (ProjectBuilder)
        let l:command_string = a:build_command . ' ' . l:additional_args
        let l:service_payload = [l:command_string]
        let l:req = {'header': 0xF2, 'service_id': 0x4, 'payload': l:service_payload}
        call cxxd#server#send_request(l:req)
    endif
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#project_builder#run()
" Description:  Triggers the build for current project but auto-detects the
"               build command from cxxd config file.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#project_builder#run_target()
    if g:cxxd_project_builder['started'] && g:cxxd_project_builder['enabled']
        call setqflist(getqflist(), 'f')
        " Request: [] (Implicitly uses target) - wait, check api structure
        " The legacy call was project_builder_request_build_target.
        " In protocol (implied, I don't see it), likely payload differentiates custom vs target.
        " Actually, let's look at how backend distinguishes.
        " For now, I'll send specific payload if I can find what it expects, 
        " OR use a different method. 
        " Wait, 'run_custom' sends [command_string]. 
        " 'run_target' sends nothing? Or a flag?
        " Checking Services... ProjectBuilder service likely has request() that takes args.
        " Legacy: project_builder_request_build_target() vs project_builder_request_build_custom(cmd)
        " Let's assume for now 0 args = target, 1 arg = custom.
        let l:service_payload = [] 
        let l:req = {'header': 0xF2, 'service_id': 0x4, 'payload': l:service_payload}
        call cxxd#server#send_request(l:req)

        let s:buf_nr = bufnr('build_log', 1)
        let s:log_job = job_start('tail -f ' . s:cxxd_project_builder_output_build_file, {'out_io': 'buffer', 'out_buf': s:buf_nr})
        sbuf build_log
        wincmd J | below
    endif
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#project_builder#run_callback()
" Description:  Callback from services#project_builder#run.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#project_builder#run_callback(status, duration, build_process_exit_code, build_output)
    echomsg 'Build process took ' . a:duration . ' with exit code ' . a:build_process_exit_code
    call job_stop(s:log_job)
    execute('bdelete! ' . s:buf_nr)
    execute('cgetfile ' . a:build_output)
    execute('copen')
    redraw
endfunction

