" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#source_code_model#indexer#run_on_single_file()
" Description:  Runs indexer on a single file.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#source_code_model#indexer#run_on_single_file(filename)
    if g:cxxd_src_code_model['started'] && g:cxxd_src_code_model['services']['indexer']['enabled']
        let l:service_payload = [0x0, 0x0, a:filename]
        let l:req = {'header': 0xF2, 'service_id': 0x0, 'payload': l:service_payload}
        call cxxd#server#send_request(l:req)
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
        let l:service_payload = [0x0, 0x1]
        let l:req = {'header': 0xF2, 'service_id': 0x0, 'payload': l:service_payload}
        call cxxd#server#send_request(l:req)
    endif
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#source_code_model#indexer#run_on_directory_callback()
" Description:  Running indexer on a directory completed.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#source_code_model#indexer#run_on_directory_callback(status)
    if a:status == v:true
        " Only print if it was actually doing something?
        " The server will tell us via callback when it finishes.
        " If it finishes instantly, maybe it was cached.
        echomsg 'Indexing finished.'
        if g:cxxd_fetch_all_diagnostics_upon_startup != 0
            call cxxd#services#source_code_model#indexer#fetch_all_diagnostics(
\               g:cxxd_fetch_all_diagnostics_sorting_strategies['severity_desc']
\           )
        endif
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
        let l:service_payload = [0x0, 0x2, a:filename]
        let l:req = {'header': 0xF2, 'service_id': 0x0, 'payload': l:service_payload}
        call cxxd#server#send_request(l:req)
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
        let l:service_payload = [0x0, 0x3, v:true]
        let l:req = {'header': 0xF2, 'service_id': 0x0, 'payload': l:service_payload}
        call cxxd#server#send_request(l:req)
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
        call cxxd#services#source_code_model#indexer#drop_all()
        call cxxd#services#source_code_model#indexer#run_on_directory()
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
            call cxxd#utils#serialize_current_buffer_contents(l:contents_filename)
        endif
        let l:service_payload = [0x0, 0x10, l:contents_filename, a:line, a:col]
        let l:req = {'header': 0xF2, 'service_id': 0x0, 'payload': l:service_payload}
        call cxxd#server#send_request(l:req)
    endif
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#source_code_model#indexer#find_all_references_callback()
" Description:  Found references.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#source_code_model#indexer#find_all_references_callback(status, references)
    if a:status == v:true
        call setqflist(a:references, 'r')
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
        let l:service_payload = [0x0, 0x11, a:fetch_sorting_strategy]
        let l:req = {'header': 0xF2, 'service_id': 0x0, 'payload': l:service_payload}
        call cxxd#server#send_request(l:req)
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
        call setqflist(a:diagnostics, 'r')
        redraw
    else
        echohl WarningMsg | echomsg 'Something went wrong with source-code-model (indexer-fetch-all-diagnostics) service. See Cxxd server log for more details!' | echohl None
    endif
endfunction




" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#source_code_model#indexer#fetch_all_definitions()
" Description:  Fetches all default definitions.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#source_code_model#indexer#fetch_all_definitions()
    if g:cxxd_src_code_model['started'] && g:cxxd_src_code_model['services']['indexer']['enabled']
        let l:service_payload = [0x0, 0x12]
        let l:req = {'header': 0xF2, 'service_id': 0x0, 'payload': l:service_payload}
        call cxxd#server#send_request(l:req)
    endif
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#source_code_model#indexer#fetch_all_definitions_callback()
" Description:  Definitions fetched.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#source_code_model#indexer#fetch_all_definitions_callback(status, definitions_file)
    if a:status == v:true
        if exists('*fzf#run')
            " Use fzf if available - stream directly from file for performance
            let l:range_calc = 'dim=${FZF_PREVIEW_LINES:-20}; start=$(($line - $dim/2)); [ $start -lt 1 ] && start=1; end=$(($line + $dim/2))'
            if executable('bat')
                let l:preview_cmd = 'file=$(echo {2} | cut -d: -f1); line=$(echo {2} | cut -d: -f2); '.l:range_calc.'; bat --language cpp --line-range $start:$end --style=numbers --color=always --highlight-line $line $file'
            elseif executable('batcat')
                let l:preview_cmd = 'file=$(echo {2} | cut -d: -f1); line=$(echo {2} | cut -d: -f2); '.l:range_calc.'; batcat --language cpp --line-range $start:$end --style=numbers --color=always --highlight-line $line $file'
            elseif executable('highlight')
                let l:preview_cmd = 'file=$(echo {2} | cut -d: -f1); line=$(echo {2} | cut -d: -f2); '.l:range_calc.'; cat $file | sed -n "$start,$end p" | highlight -O ansi --syntax cpp --force'
            else
                let l:preview_cmd = 'file=$(echo {2} | cut -d: -f1); line=$(echo {2} | cut -d: -f2); '.l:range_calc.'; cat $file | sed -n "$start,$end p"'
            endif
            call fzf#run(fzf#wrap({
            \ 'source': 'cat ' . a:definitions_file,
            \ 'sink': function('cxxd#services#source_code_model#indexer#fzf_sink'),
            \ 'options': ['--delimiter', '\t', '--preview', l:preview_cmd, '--preview-window', 'right:50%', '--ansi'],
            \ }))
        else
            " Fallback to quickfix - read file and parse
python3 << EOF
import json
import vim
defs = []
with open(vim.eval('a:definitions_file'), 'r') as f:
    # Format: context \t filename:line:column
    for line in f:
        parts = line.strip().split('\t')
        context = parts[0]
        loc_parts = parts[1].split(':')
        filename = loc_parts[0])
        lnum = loc_parts[1]
        col = loc_parts[2]
        defs.append({'filename': filename, 'lnum': lnum, 'col': col, 'text': context})
vim.command("let l:qflist = " + json.dumps(defs))
EOF
            call setqflist(l:qflist, 'r')
            execute('copen')
            redraw
        endif
    else
        echohl WarningMsg | echomsg 'Something went wrong with source-code-model (indexer-fetch-all-definitions) service. See Cxxd server log for more details!' | echohl None
    endif
endfunction

function! cxxd#services#source_code_model#indexer#fzf_sink(line)
    " Line format: context \t filename:line:column
    let l:parts = split(a:line, '\t')
    if len(l:parts) >= 2
        let l:location = split(l:parts[1], ':')
        let l:filename = l:location[0]
        let l:lineno = l:location[1]
        execute 'e ' . l:filename
        execute l:lineno
        normal! zz
    endif
endfunction
