set completefunc=cxxd#services#source_code_model#auto_completion#completefunc
let s:completions = []

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#source_code_model#auto_completion#completefunc()
" Description:  Our (user-defined) Vim completion function.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#source_code_model#auto_completion#completefunc(findstart, base)
    if a:findstart
        return col('.')
    endif
    return s:completions
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#source_code_model#auto_completion#run()
" Description:  On TextChangedI event we trigger source code auto_completion in (line, column) for given filename.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#source_code_model#auto_completion#run_i(filename, line, column)
    if g:cxxd_src_code_model['services']['auto_completion']['enabled']
        let l:contents_filename = '/tmp/tmp_' . fnamemodify(a:filename, ':p:t')
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
    if g:cxxd_src_code_model['services']['auto_completion']['enabled']
        " This saves us from triggering the auto-complete engine twice in a row when there are no actual modifications being done.
        " E.g. TextChangedP gets triggered just after the TextChangedI on the same character. It's redundant to react on both events.
        if cxxd#utils#is_more_modifications_done(winnr())
            let l:contents_filename = '/tmp/tmp_' . fnamemodify(a:filename, ':p:t')
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
" Description:  Populates the quickfix window with source code auto_completion.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#source_code_model#auto_completion#run_callback(status, auto_completion_candidates)
    if a:status == v:true
        let s:completions = a:auto_completion_candidates
        setlocal completeopt=menuone,noinsert,noselect
        setlocal complete=
        if !empty(s:completions)
            call complete(col('.'), s:completions)
        endif
    else
        echohl WarningMsg | echomsg 'Something went wrong with source-code-model (auto_completion) service. See Cxxd server log for more details!' | echohl None
    endif
    return ''
endfunction

