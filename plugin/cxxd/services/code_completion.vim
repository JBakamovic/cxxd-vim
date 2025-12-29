function! cxxd#services#code_completion#start()
    let l:req = {'header': 0xF1, 'service_id': 0x4, 'payload': []}
    call cxxd#server#send_request(l:req)
endfunction

function! cxxd#services#code_completion#start_callback(status)
    if a:status == v:true
        let g:cxxd_code_completion['started'] = 1
    else
        echohl WarningMsg | echomsg 'Something went wrong with code-completion service start-up. See Cxxd server log for more details!' | echohl None
    endif
endfunction

function! cxxd#services#code_completion#stop(subscribe_for_shutdown_callback)
    let l:req = {'header': 0xFE, 'service_id': 0x4, 'payload': [a:subscribe_for_shutdown_callback]}
    call cxxd#server#send_request(l:req)
endfunction

function! cxxd#services#code_completion#stop_callback(status)
    if a:status == v:true
        let g:cxxd_code_completion['started'] = 0
    else
        echohl WarningMsg | echomsg 'Something went wrong with code-completion service shut-down. See Cxxd server log for more details!' | echohl None
    endif
endfunction

function! cxxd#services#code_completion#run(filename, line, column)
    if g:cxxd_code_completion['started'] && g:cxxd_code_completion['enabled']
        if cxxd#utils#is_more_modifications_done(winnr())
            let l:contents_filename = cxxd#utils#pick_content_filename(a:filename)
            call cxxd#utils#serialize_current_buffer_contents(l:contents_filename)
            
            " Construct Request
            " Header: SEND_SERVICE (0xF2)
            " Service ID: CODE_COMPLETION (0x4)
            " Payload: [filename, contents_filename, line, column, offset, strategy]
            " Note: line2byte is 1-based index of byte at line.
            
            let l:offset = line2byte(a:line)
            let l:strategy = g:cxxd_src_code_model['services']['code_completion']['sorting_strategy']
            
            let l:service_payload = [0x0, a:filename, l:contents_filename, a:line, a:column, l:offset, l:strategy]
            let l:req = {'header': 0xF2, 'service_id': 0x4, 'payload': l:service_payload}
            
            call cxxd#server#send_request(l:req)
        endif
    endif
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#code_completion#run_callback()
" Description:  Opens up the pop-up menu populated with candidate list.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#code_completion#run_callback(status, code_completion_candidates, len)
    if a:status == v:true
        setlocal completeopt=menuone,noinsert,noselect
        setlocal complete=
        if a:len > 0
            let l:idx = cxxd#utils#last_occurence_of_non_identifier(getline('.')[0:(col('.')+1)])
            if l:idx == -1
                let l:start_completion_col = 1
            else
                let l:start_completion_col = col('.') - l:idx
            endif
            call complete(l:start_completion_col, a:code_completion_candidates)
        else
            call complete(col('.'), [])
        endif
    else
        echohl WarningMsg | echomsg 'Something went wrong with code-completion service. See Cxxd server log for more details!' | echohl None
    endif
endfunction

function! cxxd#services#code_completion#cache_warmup(filename)
    let l:last_line = line('$')
    let l:last_col = col([l:last_line, '$'])
    if g:cxxd_code_completion['started'] && g:cxxd_code_completion['enabled']
        " Payload: [request_id=1, filename, last_line, last_col]
        " CodeCompletionRequestId.CACHE_WARMUP = 0x1 (implied)
        " Let's check python side for Request IDs.
        " In cxxd/services/code_completion_service.py/CodeCompletion.__call__
        " It dispatches based on args[0].
        " Let's assume CacheWarmup is 0x1.
        
        let l:service_payload = [0x1, a:filename, l:last_line, l:last_col]
        let l:req = {'header': 0xF2, 'service_id': 0x4, 'payload': l:service_payload}
        call cxxd#server#send_request(l:req)
    endif
endfunction

