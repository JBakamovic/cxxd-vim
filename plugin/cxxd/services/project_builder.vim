" Variable that keeps the job id of running terminal
let s:build_job = v:null

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     services#project_builder#start()
" Description:  Starts the project builder background service.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#project_builder#start()
    let l:req = {'header': 0xF1, 'service_id': 0x1, 'payload': []}
    call cxxd#server#send_request(l:req)
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
    let l:req = {'header': 0xFE, 'service_id': 0x1, 'payload': [a:subscribe_for_shutdown_callback]}
    call cxxd#server#send_request(l:req)
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


function! cxxd#services#project_builder#on_build_command_received(status, cmd)
    if a:status == v:true
        echomsg "Starting build: " . a:cmd
        call setqflist([])

        " Prepare buffer for output
        let l:buf_name = 'build_log'
        let l:buf_nr = bufnr(l:buf_name)

        " Calculate max height (30%)
        let l:height = float2nr(&lines * 0.3)
        if l:height < 5
            let l:height = 5
        endif

        if l:buf_nr == -1
             " Not existing, create new split at bottom
             execute 'botright ' . l:height . 'new ' . l:buf_name
             let l:buf_nr = bufnr('%')
        else
             " Check if visible
             let l:win_id = bufwinid(l:buf_nr)
             if l:win_id == -1
                  " Not visible, split at bottom
                  execute 'botright ' . l:height . 'split'
                  execute 'buffer ' . l:buf_nr
             else
                  " Visible, focus
                  call win_gotoid(l:win_id)
                  " Force bottom? maybe. For now just resize.
                  execute 'resize ' . l:height
             endif
        endif

        " Clear buffer
        call deletebufline(l:buf_nr, 1, '$')

        " Focus buffer and auto-scroll setup
        call setbufvar(l:buf_nr, '&buftype', 'nofile')
        call setbufvar(l:buf_nr, '&bufhidden', 'hide')
        call setbufvar(l:buf_nr, '&swapfile', 0)

        " Start Job
        if type(s:build_job) == v:t_job && job_status(s:build_job) == 'run'
            call job_stop(s:build_job)
        endif

        let s:build_job = job_start(['/bin/sh', '-c', a:cmd], {
        \ 'out_io': 'buffer',
        \ 'out_buf': l:buf_nr,
        \ 'err_io': 'buffer',
        \ 'err_buf': l:buf_nr,
        \ 'exit_cb': 'cxxd#services#project_builder#on_build_exit'
        \ })

        " Ensure window is open and at bottom
        let l:win_id = bufwinid(l:buf_nr)
        if l:win_id != -1
             call win_execute(l:win_id, 'normal! G')
             wincmd p " Restore focus to previous window
        endif

    else
        echohl ErrorMsg | echomsg 'Failed to resolve build command.' | echohl None
    endif
endfunction

function! cxxd#services#project_builder#on_build_exit(job, status)
    echomsg 'Build finished with exit code: ' . a:status
    let l:buf_nr = bufnr('build_log')
    if l:buf_nr != -1
        " Populate quickfix from the buffer content
        let l:lines = getbufline(l:buf_nr, 1, '$')
        call setqflist([], 'r', {'title': 'Build Output', 'lines': l:lines})
        " make qf window open if there are errors (heuristic: exit code != 0 or parsing?)
        " For now, just refresh
    endif
endfunction


" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#project_builder#pick_target()
" Description:  Interactive target picker.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#project_builder#pick_target()
    if g:cxxd_project_builder['started'] && g:cxxd_project_builder['enabled']
        " Request: [0x0] (List Targets)
        let l:req = {'header': 0xF2, 'service_id': 0x1, 'payload': [0x0]}
        call cxxd#server#send_request(l:req)
    else
        echomsg "Project Builder service not started."
    endif
endfunction

function! cxxd#services#project_builder#pick_target_callback(status, targets)
    if a:status == v:true
        let s:target_candidates = a:targets

        if empty(s:target_candidates)
             echohl WarningMsg | echomsg 'No targets defined in configuration.' | echohl None
             return
        endif

        if exists('*fzf#run')
             call fzf#run(fzf#wrap({
             \ 'source': s:target_candidates,
             \ 'sink': function('cxxd#services#project_builder#pick_target_handler_fzf'),
             \ 'options': '--prompt "Select Build Target> "'
             \ }))
        else
            let l:min_popup_height = len(s:target_candidates) > 10 ? 10 : len(s:target_candidates)
            call popup_menu(s:target_candidates, #{
            \ callback: 'cxxd#services#project_builder#pick_target_handler_popup',
            \ title: ' Select Build Target ',
            \ highlight: 'Question',
            \ filter: 'popup_filter_menu',
            \ border: [],
            \ padding: [1,1,1,1],
            \ minheight: l:min_popup_height,
            \ maxheight: 40,
            \ minwidth: 60,
            \ maxwidth: 60
            \})
        endif
    else
        echohl ErrorMsg | echomsg 'Failed to list targets.' | echohl None
    endif
endfunction

function! cxxd#services#project_builder#pick_target_handler_fzf(target)
    let l:target_name = substitute(a:target, ' \[.*$', '', '')
    call cxxd#services#project_builder#run_target_by_name(l:target_name)
endfunction

function! cxxd#services#project_builder#pick_target_handler_popup(id, result)
    if a:result != -1
        let l:target_entry = s:target_candidates[a:result - 1]
        let l:target_name = substitute(l:target_entry, ' \[.*$', '', '')
        call cxxd#services#project_builder#run_target_by_name(l:target_name)
    endif
endfunction

function! cxxd#services#project_builder#run_target_by_name(target_name)
    echomsg "Requesting build for target: " . a:target_name
    " Request: [0x1, target_name] (Run Target)
    let l:service_payload = [0x1, a:target_name]
    let l:req = {'header': 0xF2, 'service_id': 0x1, 'payload': l:service_payload}
    call cxxd#server#send_request(l:req)
endfunction
