let s:show_definition_in_preview_window = v:false
let s:defaults = {
        \ 'height': 15,
        \ 'mouseclick': 'button',
        \ 'scrollbar': v:true,
        \ 'number': v:false,
        \ 'offset': 0,
        \ 'sign': {'linehl': 'CursorLine'},
        \ 'scrollup': "\<c-k>",
        \ 'scrolldown': "\<c-j>",
        \ 'halfpageup': "\<c-u>",
        \ 'halfpagedown': "\<c-d>",
        \ 'fullpageup': "\<c-b>",
        \ 'fullpagedown': "\<c-f>",
        \ 'close': 'x'
        \ }
let s:get = {x -> get(b:, 'qfpreview', get(g:, 'qfpreview', {}))->get(x, s:defaults[x])}

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#source_code_model#go_to_definition#run()
" Description:  Jumps to the definition of a symbol under the cursor.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#source_code_model#go_to_definition#run(filename, line, col, show_definition_in_preview_window)
    if g:cxxd_src_code_model['started'] && g:cxxd_src_code_model['services']['go_to_definition']['enabled']
        let s:show_definition_in_preview_window = a:show_definition_in_preview_window
        " If buffer contents are modified but not saved, we need to serialize contents of the current buffer into temporary file.
        let l:contents_filename = cxxd#utils#pick_content_filename(a:filename)
        if cxxd#utils#is_more_modifications_done(winnr())
            "echomsg 'Serializing buffer contents from GO-TO-DEFINITION.'
            call cxxd#utils#serialize_current_buffer_contents(l:contents_filename)
        endif
        python3 cxxd.api.source_code_model_go_to_definition_request(
\           server_handle,
\           vim.eval('a:filename'),
\           vim.eval('l:contents_filename'),
\           vim.eval('a:line'),
\           vim.eval('a:col')
\       )
    endif
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#services#source_code_model#go_to_definition#run_callback()
" Description:  Jumps to the definition found.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#services#source_code_model#go_to_definition#run_callback(status, filename, line, column)
    "echomsg "status: " . a:status . " filename: " . a:filename . " line: " . a:line . " col: " . a:column . " show: " s:show_definition_in_preview_window
    if a:status == v:true
        if a:filename != ''
            if s:show_definition_in_preview_window
                "let l:preview_cmd = 'pedit +normal' . a:line . 'G' . a:column . '| ' . a:filename
                "execute(l:preview_cmd)
                call s:preview_open(a:filename, a:line, a:column)
            else
                if expand('%:p') != a:filename
                    execute('edit ' . a:filename)
                endif
                call cursor(a:line, a:column)
            endif
        else
            echohl WarningMsg | echom 'No definition found!' | echohl None
        endif
    else
        echohl WarningMsg | echomsg 'Something went wrong with source-code-model (go-to-definition) service. See Cxxd server log for more details!' | echohl None
    endif
endfunction

function! s:preview_open(filename, line, column)
    let bufnr = bufadd(a:filename)
    let wininfo = getwininfo(win_getid())[0]
    let space_above = &lines - line('.') + 1 "wininfo.winrow - 1
    let space_below = line('.') "&lines - (wininfo.winrow + wininfo.height - 1) - &cmdheight
    let lnum = a:line
    let firstline = a:line - s:get('offset') < 1 ? 1 : a:line - s:get('offset')
    let height = s:get('height')

    let title = a:filename

    " Truncate long titles at beginning
    if len(title) > wininfo.width
        let title = '…' .. title[-(wininfo.width-4):]
    endif

    if space_above > height
        if space_above == height + 1
            let height = height - 1
        endif
        let opts = {
                \ 'line': 'cursor-1',
                \ 'pos': 'botleft'
                \ }
    elseif space_below >= height
        let opts = {
                \ 'line': 'cursor+1',
                \ 'pos': 'topleft'
                \ }
    elseif space_above > 5
        let height = space_above - 2
        let opts = {
                \ 'line': 'cursor',
                \ 'pos': 'botleft'
                \ }
    elseif space_below > 5
        let height = space_below - 2
        let opts = {
                \ 'line': 'cursor'
                \ 'pos': 'topleft'
                \ }
    elseif space_above <= 5 || space_below <= 5
        let opts = {
                \ 'line': &lines - &cmdheight,
                \ 'pos': 'botleft'
                \ }
    else
        echohl ErrorMsg
        echomsg 'Not enough space to display popup window.'
        echohl None
        return
    endif

    silent let winid = popup_create(bufnr, extend(opts, {
            \   'col': wininfo.wincol,
            \   'minheight': height,
            \   'maxheight': height,
            \   'minwidth': wininfo.width - 1,
            \   'maxwidth': wininfo.width - 1,
            \   'firstline': firstline,
            \   'title': title,
            \   'close': s:get('mouseclick'),
            \   'padding': [0,1,1,1],
            \   'border': [1,0,0,0],
            \   'borderchars': [' '],
            \   'moved': 'any',
            \   'mapping': v:false,
            \   'filter': funcref('s:popup_filter', [firstline]),
            \   'filtermode': 'n',
            \   'highlight': 'QfPreview',
            \   'scrollbar': s:get('scrollbar'),
            \   'borderhighlight': ['QfPreviewTitle'],
            \   'scrollbarhighlight': 'QfPreviewScrollbar',
            \   'thumbhighlight': 'QfPreviewThumb',
            \   'callback': {... -> !empty(s:get('sign'))
            \     ? [sign_unplace('PopUpQfPreview'), sign_undefine('QfErrorLine')]
            \     : 0
            \   }
            \ })))

    " Set firstline to zero to prevent jumps when calling win_execute() #4876
    call popup_setoptions(winid, {'firstline': 0})
    call setwinvar(winid, '&number', !!s:get('number'))

    if !empty(s:get('sign')->get('text', ''))
        call setwinvar(winid, '&signcolumn', 'number')
    endif

    if !empty(s:get('sign'))
        call sign_define('QfErrorLine', s:get('sign'))
        call sign_place(0, 'PopUpQfPreview', 'QfErrorLine', bufnr, {'lnum': lnum})
    endif

    return winid
endfunction

function! s:setheight(winid, step) abort
    let height = popup_getoptions(a:winid).minheight
    let newheight = height + a:step > 0 ? height + a:step : 1
    call popup_setoptions(a:winid, {'minheight': newheight, 'maxheight': newheight})
    if !empty(s:get('sign')->get('text', ''))
        call setwinvar(a:winid, '&signcolumn', 'number')
    endif
endfunction

function! s:popup_filter(line, winid, key) abort
    if a:key ==# s:get('scrollup')
        call win_execute(a:winid, "normal! \<c-y>")
    elseif a:key ==# s:get('scrolldown')
        call win_execute(a:winid, "normal! \<c-e>")
    elseif a:key ==# s:get('halfpageup')
        call win_execute(a:winid, "normal! \<c-u>")
    elseif a:key ==# s:get('halfpagedown')
        call win_execute(a:winid, "normal! \<c-d>")
    elseif a:key ==# s:get('fullpageup')
        call win_execute(a:winid, "normal! \<c-b>")
    elseif a:key ==# s:get('fullpagedown')
        call win_execute(a:winid, "normal! \<c-f>")
    elseif a:key ==# s:get('close')
        call popup_close(a:winid)
    elseif a:key ==# 'g'
        call win_execute(a:winid, 'normal! gg')
    elseif a:key ==# 'G'
        call win_execute(a:winid, 'normal! G')
    elseif a:key ==# '+'
        call s:setheight(a:winid, 1)
    elseif a:key ==# '-'
        call s:setheight(a:winid, -1)
    elseif a:key ==# 'r'
        call popup_setoptions(a:winid, {'firstline': a:line})
        call popup_setoptions(a:winid, {'firstline': 0})
        " Note: after popup_setoptions() 'signcolumn' needs to be reset again
        if !empty(s:get('sign')->get('text', ''))
            call setwinvar(a:winid, '&signcolumn', 'number')
        endif
    else
        return v:false
    endif
    return v:true
endfunction
