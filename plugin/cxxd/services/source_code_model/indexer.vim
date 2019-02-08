" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#source_code_model#indexer#run_on_single_file()
" Description:  Runs indexer on a single file.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#source_code_model#indexer#run_on_single_file(filename)
    if g:cxxd_src_code_model['started'] && g:cxxd_src_code_model['services']['indexer']['enabled']
        python cxxd.api.source_code_model_indexer_run_on_single_file_request(
\           server_handle,
\           vim.eval('a:filename')
\       )
    endif
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#source_code_model#indexer#run_on_single_file_callback()
" Description:  Running indexer on a single file completed.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#source_code_model#indexer#run_on_single_file_callback(status)
    if a:status != v:true
        echohl WarningMsg | echomsg 'Something went wrong with source-code-model (indexer-run-on-single-file) service. See Cxxd server log for more details!' | echohl None
    endif
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#source_code_model#indexer#run_on_directory()
" Description:  Runs indexer on a whole directory.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#source_code_model#indexer#run_on_directory()
    if g:cxxd_src_code_model['started'] && g:cxxd_src_code_model['services']['indexer']['enabled']
        echomsg 'Indexing started ... It may take a while if it is run for the first time.'
        python cxxd.api.source_code_model_indexer_run_on_directory_request(server_handle)
    endif
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#source_code_model#indexer#run_on_directory_callback()
" Description:  Running indexer on a directory completed.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#source_code_model#indexer#run_on_directory_callback(status)
    if a:status == v:true
        echomsg 'Indexing successfully completed.'
        call cxxd#services#source_code_model#indexer#fetch_all_diagnostics(
\           g:cxxd_fetch_all_diagnostics_sorting_strategies['severity_desc']
\       )
    else
        echohl WarningMsg | echomsg 'Something went wrong with source-code-model (indexer-run-on-directory) service. See Cxxd server log for more details!' | echohl None
    endif
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#source_code_model#indexer#run_on_directory_callback()
" Description:  Drops index for given file from the indexer.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#source_code_model#indexer#drop_single_file(filename)
    if g:cxxd_src_code_model['started'] && g:cxxd_src_code_model['services']['indexer']['enabled']
        python cxxd.api.source_code_model_indexer_drop_single_file_request(server_handle, vim.eval('a:filename'))
    endif
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#source_code_model#indexer#drop_single_file_callback()
" Description:  Dropping single file from indexing results completed.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#source_code_model#indexer#drop_single_file_callback(status)
    if a:status != v:true
        echohl WarningMsg | echomsg 'Something went wrong with source-code-model (indexer-drop-single-file) service. See Cxxd server log for more details!' | echohl None
    endif
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#source_code_model#indexer#drop_all()
" Description:  Drops all of the indices from the indexer.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#source_code_model#indexer#drop_all()
    if g:cxxd_src_code_model['started'] && g:cxxd_src_code_model['services']['indexer']['enabled']
        python cxxd.api.source_code_model_indexer_drop_all_request(server_handle, True)
    endif
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#source_code_model#indexer#drop_all()
" Description:  Dropping all indices from indexing results completed.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#source_code_model#indexer#drop_all_callback(status)
    if a:status == v:true
        echomsg 'Indexing symbol database successfully dropped ...'
    else
        echohl WarningMsg | echomsg 'Something went wrong with source-code-model (indexer-drop-all) service. See Cxxd server log for more details!' | echohl None
    endif
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#source_code_model#indexer#drop_all_and_run_on_directory()
" Description:  Drops the index database and runs indexer again (aka reindexing operation)
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#source_code_model#indexer#drop_all_and_run_on_directory()
    if g:cxxd_src_code_model['started'] && g:cxxd_src_code_model['services']['indexer']['enabled']
        echomsg 'About to drop symbol database and re-run the source code indexer ...'
        python cxxd.api.source_code_model_indexer_drop_all_and_run_on_directory_request(server_handle)
    endif
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#source_code_model#indexer#find_all_references()
" Description:  Finds project-wide references of a symbol under the cursor.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#source_code_model#indexer#find_all_references(filename, line, col)
    if g:cxxd_src_code_model['started'] && g:cxxd_src_code_model['services']['indexer']['enabled']
        " If buffer contents are modified but not saved, we need to serialize contents of the current buffer into temporary file.
        let l:contents_filename = cxxd#utils#pick_content_filename(a:filename)
        if cxxd#utils#is_more_modifications_done(winnr())
            echomsg 'Serializing buffer contents from FIND-ALL-REFERENCES.'
            call cxxd#utils#serialize_current_buffer_contents(l:contents_filename)
        endif
        python cxxd.api.source_code_model_indexer_find_all_references_request(
\           server_handle,
\           vim.eval('l:contents_filename'),
\           vim.eval('a:line'),
\           vim.eval('a:col')
\       )
    endif
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#source_code_model#indexer#find_all_references_callback()
" Description:  Found references.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#source_code_model#indexer#find_all_references_callback(status, references)
    if a:status == v:true
python << EOF
import vim
with open(vim.eval('a:references'), 'r') as f:
    vim.eval("setqflist([" + f.read() + "], 'r')")
EOF
        execute('copen')
        redraw
    else
        echohl WarningMsg | echomsg 'Something went wrong with source-code-model (indexer-find-all-references) service. See Cxxd server log for more details!' | echohl None
    endif
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#source_code_model#indexer#fetch_all_diagnostics()
" Description:  Fetches all of the source code issues/diagnostics.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#source_code_model#indexer#fetch_all_diagnostics(fetch_sorting_strategy)
    if g:cxxd_src_code_model['started'] && g:cxxd_src_code_model['services']['indexer']['enabled']
        python cxxd.api.source_code_model_indexer_fetch_all_diagnostics_request(
\           server_handle,
\           vim.eval("a:fetch_sorting_strategy")
\       )
    endif
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#source_code_model#indexer#fetch_all_diagnostics_callback()
" Description:  Diagnostics.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#source_code_model#indexer#fetch_all_diagnostics_callback(status, diagnostics)
    if a:status == v:true
        if len(a:diagnostics)
            echohl WarningMsg | echomsg 'Some issues during source code indexing were found. For better experience, please inspect those in QuickFix window.' | echohl None
        else
            echohl MoreMsg | echomsg 'Kewl. No issues were found with the code.' | echohl None
        endif
python << EOF
import vim
with open(vim.eval('a:diagnostics'), 'r') as f:
    vim.eval("setqflist([" + f.read() + "], 'r')")
EOF
        execute('copen')
        redraw
    else
        echohl WarningMsg | echomsg 'Something went wrong with source-code-model (indexer-fetch-all-diagnostics) service. See Cxxd server log for more details!' | echohl None
    endif
endfunction

