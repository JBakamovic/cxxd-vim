let s:target_candidates = ''
let s:target_selected_idx = -1
let s:target_selected = ''
let s:symbol_candidates = ''
let s:symbol_selected_idx = -1
let s:asm_winnr = 0
let s:asm_line = 0
let s:asm_col = 0

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#disassembly#start()
" Description:  Starts the disassembly background service.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#disassembly#start()
    if g:cxxd_disassembly['enabled']
        python3 cxxd.api.disassembly_start(server_handle)
    endif
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#disassembly#start_callback()
" Description:  Callback from cxxd#services#disassembly#start.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#disassembly#start_callback(status)
    if a:status == v:true
        let g:cxxd_disassembly['started'] = 1
    else
        echohl WarningMsg | echomsg 'Something went wrong with disassembly service start-up. See Cxxd server log for more details!' | echohl None
    endif
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#disassembly#stop()
" Description:  Stops the disassembly background service.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#disassembly#stop(subscribe_for_shutdown_callback)
    if g:cxxd_disassembly['enabled']
        python3 cxxd.api.disassembly_stop(server_handle, vim.eval('a:subscribe_for_shutdown_callback'))
    endif
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#disassembly#stop_callback()
" Description:  Callback from cxxd#services#disassembly#stop.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#disassembly#stop_callback(status)
    if a:status == v:true
        let g:cxxd_disassembly['started'] = 0
    else
        echohl WarningMsg | echomsg 'Something went wrong with disassembly service shut-down. See Cxxd server log for more details!' | echohl None
    endif
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#disassembly#pick_target()
" Description:  Retrieves the list of targets to pick from.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#disassembly#pick_target()
    if g:cxxd_disassembly['started'] && g:cxxd_disassembly['enabled']
        python3 cxxd.api.disassembly_list_targets(server_handle)
    endif
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#disassembly#pick_target_callback()
" Description:  Callback from cxxd#services#disassembly#pick_target. This is
"               This is where we present the list of targets in a popup menu
"               which user can use to select an entry (target of interest).
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#disassembly#pick_target_callback(status, target_candidates, nr_of_targets)
    if a:status == v:true
        let s:target_candidates = a:target_candidates
python3 << EOF
import vim
min_popup_height = 10 if int(vim.eval('a:nr_of_targets')) > 10 else int(vim.eval('a:nr_of_targets'))
with open(vim.eval('a:target_candidates'), 'r') as f:
    vim.eval("popup_menu([" + f.read() + """],
           #{  title: \'Select the target\',
               callback: 'cxxd#services#disassembly#select_target_from_pick_target_callback',
               highlight: 'Question',
               filter: 's:popup_filter',
               minheight: """ + str(min_popup_height) + """,
               maxheight: 40,
               minwidth: 120,
               maxwidth: 120
            }
       )"""
    )
EOF
        redraw
    else
        let s:target_candidates = ''
        echohl WarningMsg | echomsg 'Something went wrong with disassembly service. See Cxxd server log for more details!' | echohl None
    endif
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#disassembly#select_target_from_pick_target_callback()
" Description:  Popup menu callback from cxxd#services#disassembly#pick_target_callback.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#disassembly#select_target_from_pick_target_callback(id, target_entry)
    if a:target_entry < 1
        let s:target_selected_idx = -1
        return
    endif

    let s:target_selected_idx = a:target_entry - 1
    echomsg 'Target selected ' . s:target_selected_idx
python3 << EOF
import vim
with open(vim.eval('s:target_candidates'), 'r') as f:
    candidates = f.readlines()[0].split(',')
    selected = candidates[int(vim.eval('s:target_selected_idx'))]
    vim.command('let s:target_selected=' + selected)
EOF
    echomsg 'Target selected ' . s:target_selected
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#disassembly#pick_symbol()
" Description:  Retrives the list of symbols which match to the symbol located at (filename, line, column)
"               and in previously selected target.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#disassembly#pick_symbol(filename, line, column)
    if g:cxxd_disassembly['started'] && g:cxxd_disassembly['enabled'] && s:target_selected != ''
        python3 cxxd.api.disassembly_list_symbol_candidates(server_handle, vim.eval('s:target_selected'), vim.eval('a:filename'), vim.eval('a:line'), vim.eval('a:column'))
    endif
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#disassembly#pick_symbol_callback()
" Description:  Callback from cxxd#services#disassembly#pick_symbol.
"               This is where we present the list of symbols in a popup menu
"               which user can use to select an entry (symbol of interest).
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#disassembly#pick_symbol_callback(status, symbol_candidates, nr_of_symbols)
    if a:status == 1
        let s:symbol_candidates = a:symbol_candidates
        if a:nr_of_symbols > 0
python3 << EOF
import vim
min_popup_height = 10 if int(vim.eval('a:nr_of_symbols')) > 10 else int(vim.eval('a:nr_of_symbols'))
with open(vim.eval('a:symbol_candidates'), 'r') as f:
    vim.eval("popup_menu([" + f.read() + """],
           #{  title: \'Select the symbol\',
               callback: 'cxxd#services#disassembly#select_symbol_from_pick_symbol_callback',
               highlight: 'Question',
               filter: 's:popup_filter',
               minheight: """ + str(min_popup_height) + """,
               maxheight: 40,
               minwidth: 120,
               maxwidth: 240
            }
       )"""
   )
EOF
        else
            echohl WarningMsg | echomsg 'No symbol candidates found. Symbol is most likely inlined or not visible from current translation unit. Try with another one!' | echohl None
        endif
    else
        let s:symbol_candidates = ''
        echohl WarningMsg | echomsg 'Something went wrong with disassembly service. See Cxxd server log for more details!' | echohl None
    endif
    redraw
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#disassembly#select_symbol_from_pick_symbol_callback()
" Description:  Popup menu callback from cxxd#services#disassembly#pick_symbol_callback.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#disassembly#select_symbol_from_pick_symbol_callback(id, symbol_entry)
    if a:symbol_entry < 1
        let s:symbol_selected_idx = -1
        return
    endif

    let s:symbol_selected_idx = a:symbol_entry - 1
    echomsg 'Symbol selected ' . s:symbol_selected_idx
    call cxxd#services#disassembly#run()
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#disassembly#run()
" Description:  Disassembles the selected target and jumps to the selected symbol.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#disassembly#run()
    if g:cxxd_disassembly['started'] && g:cxxd_disassembly['enabled'] && s:target_selected != '' && s:symbol_selected_idx != -1
        python3 cxxd.api.disassembly_run(server_handle, vim.eval('s:target_selected'), vim.eval('s:symbol_selected_idx'))
    endif
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#disassembly#run_callback()
" Description:  Callback from cxxd#services#disassembly#run. Displays the disassembled binary and jumps to the selected symbol.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#disassembly#run_callback(status, disassembly_output, address, offset)
    if a:status == v:true
        if bufloaded(a:disassembly_output) == 0
            execute('vs' . a:disassembly_output)
        else
            let l:bufnr = bufnr(a:disassembly_output)
            let l:winnr = win_findbuf(l:bufnr)
            call win_gotoid(l:winnr[0])
            call cursor(1, 1)
            " It's possible that we switched between different targets in the
            " meantime so we have to force Vim to reload the contents
            execute('e')
        endif
        execute('set ft=gas')
        execute('setlocal readonly')
        execute('setlocal nomodifiable')
        call search(a:address . ':')
    else
        echohl WarningMsg | echomsg 'Something went wrong with disassembly service. See Cxxd server log for more details!' | echohl None
    endif
endfunction

function! cxxd#services#disassembly#asm_instruction_info()
    let s:asm_winnr = v:beval_winnr
    let s:asm_line = v:beval_lnum
    let s:asm_col = v:beval_col
    if v:beval_text != ''
        python3 cxxd.api.disassembly_asm_doc(
\                   server_handle,
\                   vim.eval('v:beval_text')
\               )
    endif
    return ''
endfunction

function! cxxd#services#disassembly#asm_instruction_info_callback(status, tooltip, description, url)
    if a:status == v:true
        let pos = screenpos(s:asm_winnr, s:asm_line, s:asm_col)
        let l:descr = ["== Short description ==", "", a:tooltip, "", "Link: " . a:url, "", "== More details ==", "", a:description]
        call popup_create(l:descr, #{
        \ line: pos.row,
        \ col: pos.col,
        \ minwidth: 80,
        \ maxwidth: 80,
        \ minheight: 2,
        \ maxheight: &lines - 1,
        \ border: [],
        \ padding: [],
        \ mapping: 0,
        \ scrollbar: 1,
        \ moved: 'WORD',
        \ mousemoved: 'WORD',
        \ drag: 1,
        \ highlight: 'Notification',
        \})
        redraw
    else
        echohl WarningMsg | echomsg 'Something went wrong with disassembly service. See Cxxd server log for more details!' | echohl None
    endif
endfunction

function s:popup_filter(winid, key) abort
    if a:key ==# "\<c-j>"
        call win_execute(a:winid, "normal! \<c-e>")
        return v:true
    elseif a:key ==# "\<c-k>"
        call win_execute(a:winid, "normal! \<c-y>")
        return v:true
    elseif a:key ==# "\<c-b>" || a:key ==# "\<PageUp>"
        call win_execute(a:winid, "normal! \<c-b>")
        return v:true
    elseif a:key ==# "\<c-f>" || a:key ==# "\<PageDown>"
        call win_execute(a:winid, "normal! \<c-f>")
        return v:true
    elseif a:key ==# "\<c-d>"
        call win_execute(a:winid, "normal! \<c-d>")
        return v:true
    elseif a:key ==# "\<c-u>"
        call win_execute(a:winid, "normal! \<c-u>")
        return v:true
    elseif a:key ==# "\<c-g>"
        call win_execute(a:winid, "normal! G")
        return v:true
    elseif a:key ==# "\<c-t>"
        call win_execute(a:winid, "normal! gg")
        return v:true
    elseif a:key ==# 'q'
        call popup_close(a:winid)
        return v:true
    endif
    return popup_filter_menu(a:winid, a:key)
endfunction
