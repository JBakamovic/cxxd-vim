set completefunc=cxxd#services#source_code_model#auto_completion#completefunc
setlocal completeopt+=menuone
let s:completions = []

function! cxxd#services#source_code_model#auto_completion#completefunc(findstart, base)
    if a:findstart
        return col('.')
    endif
    return s:completions
endfunction

"inoremap <F11> <C-R>=cxxd#services#source_code_model#auto_completion#run()<CR>
"inoremap <F12> <C-R>=ListMonths()<CR>

func! ListMonths()
  call complete(col('.'), ['January', 'February', 'March',
    \ 'April', 'May', 'June', 'July', 'August', 'September',
    \ 'October', 'November', 'December'])
  return ''
endfunc

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#source_code_model#auto_completion#run()
" Description:  Triggers the source code auto_completion for current buffer.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"function! cxxd#services#source_code_model#auto_completion#run(filename, expr_to_complete)
function! cxxd#services#source_code_model#auto_completion#run()
    let l:filename = expand('%:p')
    if g:cxxd_src_code_model['services']['auto_completion']['enabled']
        " If buffer contents are modified but not saved, we need to serialize contents of the current buffer into temporary file.
        let l:contents_filename = l:filename
        if getbufvar(l:filename, '&modified')
            let l:contents_filename = '/tmp/tmp_' . fnamemodify(l:filename, ':p:t')
            call cxxd#utils#serialize_current_buffer_contents(l:contents_filename)
        endif

        let s:completions = []
        let l:line = line('.')
        let l:col  = col('.')
        python cxxd.api.source_code_model_auto_completion_request(server_handle, vim.eval('l:filename'), vim.eval('l:contents_filename'), vim.eval('l:line'), vim.eval('l:col'))
    endif
endfunction

function! s:SendKeys(keys)
  " By default keys are added to the end of the typeahead buffer. If there are
  " already keys in the buffer, they will be processed first and may change the
  " state that our keys combination was sent for (e.g. <C-X><C-U><C-P> in normal
  " mode instead of insert mode or <C-e> outside of completion mode). We avoid
  " that by inserting the keys at the start of the typeahead buffer with the 'i'
  " option. Also, we don't want the keys to be remapped to something else so we
  " add the 'n' option.
  call feedkeys(a:keys, 'in')
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#source_code_model#auto_completion#run_callback()
" Description:  Populates the quickfix window with source code auto_completion.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#source_code_model#auto_completion#run_callback(status, auto_completion_candidates)
    if a:status == v:true
        echomsg 'Auto completion candidates: ' . a:auto_completion_candidates
        echomsg 'Type = ' . type(a:auto_completion_candidates)
        let s:completions = a:auto_completion_candidates
        call s:SendKeys("\i\<C-X>\<C-U>\<C-P>")
    else
        echohl WarningMsg | echomsg 'Something went wrong with source-code-model (auto_completion) service. See Cxxd server log for more details!' | echohl None
    endif
    return ''
endfunction

