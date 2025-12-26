" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Global job ID
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let s:cxxd_job_id = 0
let s:cxxd_server_vim_path = expand('<sfile>:p')

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#server#start()
" Description:  Starts cxxd server (Job Mode).
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#server#start(project_root_directory, ...)
    let l:project_root_directory_full_path =  fnamemodify(a:project_root_directory, ':p')
    let l:target_configuration = ''         " auto-discovery mode by default
    if a:0 > 0
        let l:target_configuration = a:1    " otherwise what user has provided to us
    endif

    " Determine path to lib/cxxd/main.py
    " plugin/cxxd/server.vim -> plugin/cxxd -> plugin -> root
    let l:plugin_root = fnamemodify(s:cxxd_server_vim_path, ':h:h:h')
    let l:script_path = l:plugin_root . '/lib/cxxd/main.py'

    " Log file path
    let l:log_file = tempname() . '_cxxd_server.log'

    let l:cmd = ['python3', l:script_path, '--project-root', l:project_root_directory_full_path, '--log-file', l:log_file]
    if l:target_configuration != ''
         call add(l:cmd, '--target-config')
         call add(l:cmd, l:target_configuration)
    endif

    echom "Starting cxxd server: " . join(l:cmd, ' ')

    if has('nvim')
        let s:cxxd_job_id = jobstart(l:cmd, {
            \ 'on_stdout': function('cxxd#job#stdout_handler'),
            \ 'on_stderr': function('cxxd#job#stderr_handler'),
            \ 'on_exit':   function('cxxd#job#exit_handler'),
            \ 'rpc': v:false
        \ })

        if s:cxxd_job_id <= 0
            echoerr "Failed to start cxxd server job!"
            return
        endif
    elseif has('job') && has('channel')
        " Vim 8 Support
        let s:cxxd_job_id = job_start(l:cmd, {
            \ 'mode': 'nl',
            \ 'out_cb': function('cxxd#job#vim8_stdout_handler'),
            \ 'err_cb': function('cxxd#job#vim8_stderr_handler'),
            \ 'exit_cb': function('cxxd#job#vim8_exit_handler')
        \ })

        if job_status(s:cxxd_job_id) == "fail"
            echoerr "Failed to start cxxd server job!"
            return
        endif
    else
        echoerr "Job support needed: NeoVim or Vim 8+ required"
        return
    endif

    " Initialize services (send start request)
    call cxxd#server#start_all_services()

    set ballooneval balloonexpr=cxxd#server#balloonexpr()
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#server#stop()
" Description:  Stops cxxd server.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#server#stop(subscribe_for_shutdown_callback)
    if has('nvim')
        if s:cxxd_job_id > 0
            call jobstop(s:cxxd_job_id)
            let s:cxxd_job_id = 0
        endif
    elseif has('job')
        if type(s:cxxd_job_id) == v:t_job && job_status(s:cxxd_job_id) == "run"
            call job_stop(s:cxxd_job_id)
            let s:cxxd_job_id = 0
        endif
    endif
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#server#send_request()
" Description:  Sends a JSON request to the server.
"               payload should be a DICT: {'header': ..., 'service_id': ..., 'payload': ...}
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#server#send_request(req)
    let l:running = 0
    if has('nvim')
        let l:running = (s:cxxd_job_id > 0)
    elseif has('job')
         let l:running = (type(s:cxxd_job_id) == v:t_job && job_status(s:cxxd_job_id) == "run")
    endif

    if !l:running
        echoerr "Cxxd server is not running!"
        return
    endif

    let l:json = json_encode(a:req)
    if has('nvim')
        call chansend(s:cxxd_job_id, l:json . "\n")
    elseif has('channel')
        let l:channel = job_getchannel(s:cxxd_job_id)
        if ch_status(l:channel) == "open"
             " ch_sendraw sends exact bytes without extra newline unless we add it
             call ch_sendraw(l:channel, l:json . "\n")
        endif
    endif
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#server#start_all_services()
" Description:  Starts all cxxd server services.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#server#start_all_services()
    let l:req = {'header': 0xF0, 'service_id': 0, 'payload': []} 
    call cxxd#server#send_request(l:req)
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#server#stop_all_services()
" Description:  Stops all cxxd server services.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#server#stop_all_services(subscribe_for_shutdown_callback)
    let l:req = {'header': 0xFD, 'service_id': 0, 'payload': []}
    call cxxd#server#send_request(l:req)
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#server#balloonexpr()
" Description:  Dispatcher for balloon expr.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#server#balloonexpr()
    let l:buf_ext = fnamemodify(bufname(v:beval_bufnr), ':e')
    if l:buf_ext == 'asm'
        return cxxd#services#disassembly#asm_instruction_info()
    else
        return cxxd#services#source_code_model#type_deduction#run()
    endif
endfunction
