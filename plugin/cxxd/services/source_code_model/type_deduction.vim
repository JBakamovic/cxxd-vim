" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#source_code_model#type_deduction#run()
" Description:  Extracts information about the underlying type (on mouse-hover).
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#source_code_model#type_deduction#run()
    if g:cxxd_src_code_model['started'] && g:cxxd_src_code_model['services']['type_deduction']['enabled']
        " Execute requests only on non-special, ordinary buffers. I.e. ignore NERD_Tree, Tagbar, quickfix and alike.
        " In case of non-ordinary buffers, buffer may not even exist on a disk and triggering the service does not
        " any make sense then.
        if getbufvar(v:beval_bufnr, "&buftype") == ''
            let l:current_buffer = fnamemodify(bufname(v:beval_bufnr), ':p')

            " If buffer contents are modified but not saved, we need to serialize contents of the current buffer into temporary file.
            let l:contents_filename = l:current_buffer
            if cxxd#utils#is_more_modifications_done(winnr('#'))
                let l:contents_filename = '/tmp/tmp_' . fnamemodify(l:current_buffer, ':p:t')
                call cxxd#utils#serialize_current_buffer_contents(l:contents_filename)
            endif
            python cxxd.api.source_code_model_type_deduction_request(server_handle, vim.eval('l:current_buffer'), vim.eval('l:contents_filename'), vim.eval('v:beval_lnum'), vim.eval('v:beval_col'))
        endif
    endif
    return ''
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#source_code_model#type_deduction#run_callback()
" Description:  Display extracted information about the type in a balloon.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#source_code_model#type_deduction#run_callback(status, deducted_type)
    if a:status == v:true
        if exists('*balloon_show')
            if a:deducted_type != ''
                call balloon_show(a:deducted_type)
            endif
        else
            echo a:deducted_type
        endif
    else
        echohl WarningMsg | echomsg 'Something went wrong with source-code-model (type-deduction) service. See Cxxd server log for more details!' | echohl None
    endif
endfunction
