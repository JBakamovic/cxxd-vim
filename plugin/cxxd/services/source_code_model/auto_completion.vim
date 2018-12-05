" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#source_code_model#auto_completion#run()
" Description:  On TextChangedI event we trigger source code auto_completion in (line, column) for given filename.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#source_code_model#auto_completion#run_i(filename, line, column)
    if g:cxxd_src_code_model['started'] && g:cxxd_src_code_model['services']['auto_completion']['enabled']
        let l:contents_filename = cxxd#utils#pick_content_filename(a:filename)
        call cxxd#utils#serialize_current_buffer_contents(l:contents_filename)
        python cxxd.api.source_code_model_auto_completion_code_complete_request(
\           server_handle,
\           vim.eval('a:filename'),
\           vim.eval('l:contents_filename'),
\           vim.eval('a:line'),
\           vim.eval('a:column'),
\           vim.eval('line2byte(a:line)'),
\           vim.eval("g:cxxd_src_code_model['services']['auto_completion']['sorting_strategy']")
\       )
    endif
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#source_code_model#auto_completion#run_p()
" Description:  On TextChangedP event we trigger source code auto_completion in (line, column) for given filename.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#source_code_model#auto_completion#run_p(filename, line, column)
    if g:cxxd_src_code_model['started'] && g:cxxd_src_code_model['services']['auto_completion']['enabled']
        " This saves us from triggering the auto-complete engine twice in a row when there are no actual modifications being done.
        " E.g. TextChangedP gets triggered just after the TextChangedI on the same character. It's redundant to react on both events.
        if cxxd#utils#is_more_modifications_done(winnr())
            let l:contents_filename = cxxd#utils#pick_content_filename(a:filename)
            call cxxd#utils#serialize_current_buffer_contents(l:contents_filename)
            python cxxd.api.source_code_model_auto_completion_code_complete_request(
\               server_handle,
\               vim.eval('a:filename'),
\               vim.eval('l:contents_filename'),
\               vim.eval('a:line'),
\               vim.eval('a:column'),
\               vim.eval('line2byte(a:line)'),
\               vim.eval("g:cxxd_src_code_model['services']['auto_completion']['sorting_strategy']")
\       )
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
        endif
    else
        echohl WarningMsg | echomsg 'Something went wrong with source-code-model (auto_completion) service. See Cxxd server log for more details!' | echohl None
    endif
endfunction

