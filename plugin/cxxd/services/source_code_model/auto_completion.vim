function! cxxd#services#source_code_model#auto_completion#start(compilation_db_path)
    if filereadable(a:compilation_db_path)
        python cxxd.api.code_completion_start(server_handle, vim.eval('a:compilation_db_path'))
    else
        echohl WarningMsg | echomsg 'code-completion requires compilation database which is not found. code-completion service will not be available.' | echohl None
    endif
endfunction

function! cxxd#services#source_code_model#auto_completion#start_callback(status)
    if a:status == v:true
        let g:cxxd_code_completion['started'] = 1
    else
        echohl WarningMsg | echomsg 'Something went wrong with code-completion service start-up. See Cxxd server log for more details!' | echohl None
    endif
endfunction

function! cxxd#services#source_code_model#auto_completion#stop(subscribe_for_shutdown_callback)
    python cxxd.api.clang_tidy_stop(server_handle, vim.eval('a:subscribe_for_shutdown_callback'))
endfunction

function! cxxd#services#source_code_model#auto_completion#stop_callback(status)
    if a:status == v:true
        let g:cxxd_code_completion['started'] = 0
    else
        echohl WarningMsg | echomsg 'Something went wrong with code-completion service shut-down. See Cxxd server log for more details!' | echohl None
    endif
endfunction

function! cxxd#services#source_code_model#auto_completion#run(filename, line, column)
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
\               vim.eval("g:cxxd_src_code_model['services']['auto_completion']['sorting_strategy']")
\           )
        endif
    endif
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#source_code_model#auto_completion#run_callback()
" Description:  Opens up the pop-up menu populated with candidate list.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#source_code_model#auto_completion#run_callback(status, auto_completion_candidates, len)
    if a:status == v:true
        setlocal completeopt=menuone,noinsert,noselect
        setlocal complete=
        if a:len > 0
            let l:idx = cxxd#utils#last_occurence_of_non_identifier(getline('.')[0:(col('.')+1)])
            if l:idx == -1
                let l:start_completion_col = 0
            else
                let l:start_completion_col = col('.') - l:idx
            endif
python << EOF
import vim
with open(vim.eval('a:auto_completion_candidates'), 'r') as f:
    vim.eval("complete(" + vim.eval('l:start_completion_col') + ", [" + f.read() + "])")
EOF
        else
            call complete(col('.'), [])
        endif
    else
        echohl WarningMsg | echomsg 'Something went wrong with source-code-model (auto_completion) service. See Cxxd server log for more details!' | echohl None
    endif
endfunction

