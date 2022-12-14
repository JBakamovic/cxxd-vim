function! cxxd#services#code_completion#start()
    python cxxd.api.code_completion_start(server_handle)
endfunction

function! cxxd#services#code_completion#start_callback(status)
    if a:status == v:true
        let g:cxxd_code_completion['started'] = 1
    else
        echohl WarningMsg | echomsg 'Something went wrong with code-completion service start-up. See Cxxd server log for more details!' | echohl None
    endif
endfunction

function! cxxd#services#code_completion#stop(subscribe_for_shutdown_callback)
    python3 cxxd.api.code_completion_stop(server_handle, vim.eval('a:subscribe_for_shutdown_callback'))
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
            python cxxd.api.code_complete_request(
\               server_handle,
\               vim.eval('a:filename'),
\               vim.eval('l:contents_filename'),
\               vim.eval('a:line'),
\               vim.eval('a:column'),
\               vim.eval('line2byte(a:line)'),
\               vim.eval("g:cxxd_src_code_model['services']['code_completion']['sorting_strategy']")
\           )
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
python << EOF
import vim
with open(vim.eval('a:code_completion_candidates'), 'r') as f:
    vim.eval("complete(" + vim.eval('l:start_completion_col') + ", [" + f.read() + "])")
EOF
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
        python cxxd.api.code_complete_cache_warmup_request(
\           server_handle,
\           vim.eval('a:filename'),
\           vim.eval('l:last_line'),
\           vim.eval('l:last_col')
\       )
    endif
endfunction

