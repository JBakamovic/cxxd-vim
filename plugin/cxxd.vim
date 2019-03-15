"
" Sanity checks
"
if exists("g:loaded_cxxdvim")
    finish
else
    if !has("clientserver")
        echohl WarningMsg |
            \ echoerr "cxxd-vim requires (G)Vim compiled with 'clientserver' feature.".
            \         " TL;DR Use GVim. Non-gui versions of Vim are usually not distributed with 'clientserver' feature compiled in." |
            \ echohl None
        call feedkeys("\<CR>")
        finish
    elseif !has("python")
        echohl WarningMsg |
            \ echoerr "cxxd-vim requires (G)Vim compiled with 'python' feature." |
            \ echohl None
        call feedkeys("\<CR>")
        finish
    endif
endif
let g:loaded_cxxdvim = 1


"
" Store cpo
"
let s:save_cpo = &cpo
set cpo&vim


"
" Cxxd fetch-all-diagnostics sorting strategies
"   Reported diagnostics may be sorted with different strategies:
"       (1) No sorting.
"       (2) By diagnostics severity (ascending order).
"       (3) By diagnostics severity (descending order).
"       (4) Alphabetically by filenames.
"
let g:cxxd_fetch_all_diagnostics_sorting_strategies = {
\                                                   'none'          : 0,
\                                                   'severity_asc'  : 1,
\                                                   'severity_desc' : 2,
\                                                   'filename'      : 3,
\}

"
" Cxxd services definition
"
let g:cxxd_src_code_model       = {
\                                   'enabled'  : 1,
\                                   'started'  : 0,
\                                   'services' : {
\                                       'indexer'                   : { 'enabled' : 1 },
\                                       'semantic_syntax_highlight' : { 'enabled' : 1 },
\                                       'diagnostics'               : { 'enabled' : 1 },
\                                       'type_deduction'            : { 'enabled' : 1 },
\                                       'go_to_definition'          : { 'enabled' : 1 },
\                                       'go_to_include'             : { 'enabled' : 1 },
\                                   }
\}

let g:cxxd_project_builder      = {
\                                   'enabled' : 1,
\                                   'started' : 0,
\}

let g:cxxd_clang_format         = {
\                                   'enabled' : 1,
\                                   'started' : 0,
\                                   'config'  : '.clang-format'
\}

let g:cxxd_clang_tidy           = {
\                                   'enabled' : 1,
\                                   'started' : 0,
\                                   'config'  : '.clang-tidy'
\}

let g:cxxd_available_services   = [
\                                   g:cxxd_src_code_model,
\                                   g:cxxd_project_builder,
\                                   g:cxxd_clang_format,
\                                   g:cxxd_clang_tidy,
\]


"
" Cxxd services integration
"
augroup cxxd_init_deinit
    autocmd!
    autocmd VimLeave                *                                           call cxxd#server#stop(v:false)
    autocmd VimEnter,WinEnter       *                                           call cxxd#utils#init_window_specific_vars()
augroup END

augroup cxxd_source_code_model_indexer
    autocmd!
    autocmd BufWritePost            *.cpp,*.cxx,*.cc,*.c,*.h,*.hh,*.hpp,*.hxx   call cxxd#services#source_code_model#indexer#run_on_single_file(expand('%:p'))
augroup END

augroup cxxd_source_code_model_diagnostics
    autocmd!
    autocmd CursorHold              *.cpp,*.cxx,*.cc,*.c,*.h,*.hh,*.hpp,*.hxx   call cxxd#services#source_code_model#diagnostics#run(expand('%:p'))
    autocmd CursorHoldI             *.cpp,*.cxx,*.cc,*.c,*.h,*.hh,*.hpp,*.hxx   call cxxd#services#source_code_model#diagnostics#run(expand('%:p'))
augroup END

augroup cxxd_source_code_model_semantic_syntax_highlight
    autocmd!
    autocmd CursorHold              *.cpp,*.cxx,*.cc,*.c,*.h,*.hh,*.hpp,*.hxx   call cxxd#services#source_code_model#semantic_syntax_highlight#run(expand('%:p'))
    autocmd CursorHoldI             *.cpp,*.cxx,*.cc,*.c,*.h,*.hh,*.hpp,*.hxx   call cxxd#services#source_code_model#semantic_syntax_highlight#run(expand('%:p'))
augroup END

augroup cxxd_clang_format
    autocmd!
    autocmd BufWritePost            *.cpp,*.cxx,*.cc,*.c,*.h,*.hh,*.hpp,*.hxx   call cxxd#services#clang_format#run(expand('%:p'))
augroup END

"
" Cxxd commands
"
:command -nargs=+ -complete=dir CxxdStart                             :call cxxd#server#start(<f-args>)
:command                        CxxdStop                              :call cxxd#server#stop(v:false)
:command                        CxxdGoToInclude                       :call cxxd#services#source_code_model#go_to_include#run(expand('%:p'), line('.'))
:command                        CxxdGoToDefinition                    :call cxxd#services#source_code_model#go_to_definition#run(expand('%:p'), line('.'), col('.'))
:command                        CxxdFindAllReferences                 :call cxxd#services#source_code_model#indexer#find_all_references(expand('%:p'), line('.'), col('.'))
:command                        CxxdFetchAllDiagnostics               :call cxxd#services#source_code_model#indexer#fetch_all_diagnostics(g:cxxd_fetch_all_diagnostics_sorting_strategies['none'])
:command                        CxxdFetchAllDiagnosticsBySeverityAsc  :call cxxd#services#source_code_model#indexer#fetch_all_diagnostics(g:cxxd_fetch_all_diagnostics_sorting_strategies['severity_asc'])
:command                        CxxdFetchAllDiagnosticsBySeverityDesc :call cxxd#services#source_code_model#indexer#fetch_all_diagnostics(g:cxxd_fetch_all_diagnostics_sorting_strategies['severity_desc'])
:command                        CxxdFetchAllDiagnosticsByAlphabet     :call cxxd#services#source_code_model#indexer#fetch_all_diagnostics(g:cxxd_fetch_all_diagnostics_sorting_strategies['filename'])
:command                        CxxdRebuildIndex                      :call cxxd#services#source_code_model#indexer#drop_all_and_run_on_directory()
:command                        CxxdAnalyzerClangTidyBuf              :call cxxd#services#clang_tidy#run(expand('%:p'), v:false)
:command                        CxxdAnalyzerClangTidyApplyFixesBuf    :call cxxd#services#clang_tidy#run(expand('%:p'), v:true)
:command -nargs=+               CxxdBuildRun                          :call cxxd#services#project_builder#run(<f-args>)

"
" TODO
"       add license on top
"       add license file?
"

"
" Cxxd default-provided key mappings
"
nmap <unique>       <F3>       :CxxdGoToInclude<CR>                             | " Open file (header-include) under the cursor
imap <unique>       <F3>       <ESC>:CxxdGoToInclude<CR>i
nmap <unique>       <S-F3>     :vsp <CR>:CxxdGoToInclude<CR>                    | " Open file (header-include) under the cursor in a vertical split
imap <unique>       <S-F3>     <ESC>:vsp <CR>:CxxdGoToInclude<CR>i
nmap <unique>       <F12>      :CxxdGoToDefinition<CR>                          | " Jump to symbol definition
imap <unique>       <F12>      <ESC>:CxxdGoToDefinition<CR>i
nmap <unique>       <S-F12>    :vsp <CR>:CxxdGoToDefinition<CR>                 | " Jump to symbol definition in a vertical split
imap <unique>       <S-F12>    <ESC>:vsp <CR>:CxxdGoToDefinition<CR>i
nmap <unique>       <C-\>s     :CxxdFindAllReferences<CR>                       | " Find all references of symbol under the cursor
imap <unique>       <C-\>s     <ESC>:CxxdFindAllReferences<CR>i
nmap <unique>       <C-\>d     :CxxdFetchAllDiagnosticsBySeverityDesc<CR>       | " Fetch all diagnostics sorted by severity descending
imap <unique>       <C-\>d     <ESC>:CxxdFetchAllDiagnosticsBySeverityDesc<CR>i
nmap <unique>       <C-\>r     :CxxdRebuildIndex<CR>                            | " Rebuild symbol database index for current project
imap <unique>       <C-\>r     <ESC>:CxxdRebuildIndex<CR>i
nmap <unique>       <F5>       :CxxdAnalyzerClangTidyBuf<CR>                    | " Run clang-tidy over current buffer (do not apply fixes)
imap <unique>       <F5>       <ESC>:CxxdAnalyzerClangTidyBuf<CR>i
nmap <unique>       <S-F5>     :CxxdAnalyzerClangTidyApplyFixesBuf<CR>          | " Run clang-tidy over current buffer (apply fixes)
imap <unique>       <S-F5>     <ESC>:CxxdAnalyzerClangTidyApplyFixesBuf<CR>i


"
" Important to be set to a much lower value than a default one (=4000) because some
" services act upon 'CursorHoldI' event. I.e. semantic syntax highlighting and diagnostics.
"
set updatetime=250


"
" Restore cpo
"
let &cpo = s:save_cpo
unlet s:save_cpo

