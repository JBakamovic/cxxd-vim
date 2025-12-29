" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#job#start_handler()
" Description:  Called when the job starts.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#job#start_handler(job_id, data, event)
    " No-op
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#job#stdout_handler()
" Description:  Handles JSON messages from stdout (NEOVIM).
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#job#stdout_handler(job_id, data, event)
    " Neovim passes a list of strings (lines).
    if type(a:data) == v:t_list
        for l:line in a:data
            if l:line != ''
                call s:process_message(l:line)
            endif
        endfor
    endif
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#job#vim8_stdout_handler()
" Description:  Handles JSON messages from stdout (VIM 8).
"               Signature: func(channel, msg)
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#job#vim8_stdout_handler(channel, msg)
    call s:process_message(a:msg)
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#job#stderr_handler()
" Description:  Handles stderr output (NEOVIM).
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#job#stderr_handler(job_id, data, event)
    for l:line in a:data
        if l:line != ''
            echohl ErrorMsg | echom "cxxd server error: " . l:line | echohl None
        endif
    endfor
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#job#vim8_stderr_handler()
" Description:  Handles stderr output (VIM 8).
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#job#vim8_stderr_handler(channel, msg)
    echohl ErrorMsg | echom "cxxd server error: " . a:msg | echohl None
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#job#exit_handler()
" Description:  Called when job exits (NEOVIM).
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#job#exit_handler(job_id, data, event)
    echom "cxxd server exited (Neovim)"
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#job#vim8_exit_handler()
" Description:  Called when job exits (VIM 8).
"               Signature: func(job, status)
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#job#vim8_exit_handler(job, status)
     echom "cxxd server exited (Vim 8)"
endfunction

function! s:process_message(json_str)
    try
        let l:msg = json_decode(a:json_str)
        if has_key(l:msg, 'exec')
            execute l:msg.exec
        elseif has_key(l:msg, 'call')
            let l:start_idx = stridx(l:msg.call, '(')
            if l:start_idx == -1
                " Simple function name, args separate
                 call call(l:msg.call, l:msg.args)
            else
                " It might be full legacy string "Func(1, 2)" ??
                " But Messenger sends {"call": "Func", "args": [...]}
                " So we stick to valid one.
            endif
        endif
    catch
        " Ignore partial lines or bad JSON
        " echom "cxxd: failed to decode JSON: " . a:json_str
    endtry
endfunction
