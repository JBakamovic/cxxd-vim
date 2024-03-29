" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#utils#serialize_current_buffer_contents
" Description:  Function which serializes current buffer contents to the given filename.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#utils#serialize_current_buffer_contents(to_filename)
python3 << EOF
import vim
with open(vim.eval('a:to_filename'), "w") as f:
    f.writelines(line + '\n' for line in vim.current.buffer)
EOF
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#utils#pick_content_filename
" Description:  Function which short-circuits the input to output if input filename has not been modified.
"               Otherwise, it returns a new output filename whose name is generated out of the input filename base.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#utils#pick_content_filename(filename)
    if getbufvar(a:filename, '&modified')
        return '/tmp/tmp_' . fnamemodify(a:filename, ':p:t')
    else
        return a:filename
    endif
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#utils#init_window_specific_vars
" Description:  Function which instantiates and initializes window-specific variables which we use to emulate
"               some inexisting events in Vim (e.g. 'ViewportChanged').
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#utils#init_window_specific_vars()
    if !exists('w:text_changed')                | let w:text_changed                = v:false | endif
    if !exists('w:text_changed_i')              | let w:text_changed_i              = v:false | endif
    if !exists('w:previous_num_of_changes')     | let w:previous_num_of_changes     = 0       | endif
    if !exists('w:more_modifications_done')     | let w:more_modifications_done     = v:false | endif
    if !exists('w:previous_visible_line_begin') | let w:previous_visible_line_begin = 0       | endif
    if !exists('w:previous_visible_line_end')   | let w:previous_visible_line_end   = 0       | endif
    if !exists('w:viewport_changed')            | let w:viewport_changed            = v:false | endif
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#utils#is_more_modifications_done
" Description:  Check if more modifications has been done in given window.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#utils#is_more_modifications_done(winnr)
    return getwinvar(a:winnr, 'text_changed') && getwinvar(a:winnr, 'more_modifications_done')
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#utils#is_viewport_changed
" Description:  Check if viewport has been changed for given window.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#utils#is_viewport_changed(winnr)
    return getwinvar(a:winnr, 'viewport_changed')
endfunction

function! cxxd#utils#modifications_handler_i(winnr)
    call setwinvar(a:winnr, 'text_changed', v:true)
    call setwinvar(a:winnr, 'text_changed_i', v:true)
endfunction

function! cxxd#utils#modifications_handler_p(winnr)
    if getwinvar(a:winnr, 'text_changed_i')
        call setwinvar(a:winnr, 'text_changed', v:false)
        call setwinvar(a:winnr, 'text_changed_i', v:false)
    else
        call setwinvar(a:winnr, 'text_changed', v:true)
    endif
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#utils#modifications_handler
" Description:  Handler which checks if more modifications has been done in given window and accordingly set relevant variables.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#utils#modifications_handler(winnr)
    if getbufinfo(winbufnr(a:winnr))[0].changed
        let l:previous_num_of_changes = getwinvar(a:winnr, 'previous_num_of_changes')
        let l:num_of_changes          = getbufinfo(winbufnr(a:winnr))[0].changedtick
        call setwinvar(a:winnr, 'previous_num_of_changes', l:num_of_changes)
        call setwinvar(a:winnr, 'more_modifications_done', l:num_of_changes != l:previous_num_of_changes)
    else
        call setwinvar(a:winnr, 'more_modifications_done', v:false)
    endif
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#utils#viewport_handler
" Description:  Handler which checks if viewport has been changed for given window and accordingly set relevant variables.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#utils#viewport_handler(winnr, current_visible_line_begin, current_visible_line_end)
    let l:previous_visible_line_begin = getwinvar(a:winnr, 'previous_visible_line_begin')
    let l:previous_visible_line_end   = getwinvar(a:winnr, 'previous_visible_line_end')

    " Because we are missing a proper event support in Vim, we are using a 'CursorHold(I)' event context
    " to emulate 'ViewportChanged' event. We just need to filter out unnecessary 'CursorHold' events ...
    "   1. CursorHold(I) events can be triggered by moving the cursor horizontally
    "       * In which case we will report back that viewport
    "         hasn't been changed
    "   2. CursorHold(I) events can be triggered by moving cursor vertically
    "      but not enough to change the viewport (i.e. moving cursor across
    "      the lines but without changing the first and last line visible
    "      in the given window)
    "       * In which case we will still report back that viewport
    "         hasn't been changed
    "   3. CursorHold(I) events can be triggered by moving cursor vertically
    "      but this time enough to impact the viewport (i.e. move
    "      cursor upwards when we are at the top of the viewport or
    "      move cursor downwards when we are the bottom of the
    "      viewport)
    "       * In which case we will report back that viewport
    "         has been changed
    let l:viewport_changed = v:false
    if a:current_visible_line_begin != l:previous_visible_line_begin
        call setwinvar(a:winnr, 'previous_visible_line_begin', a:current_visible_line_begin)
        let l:viewport_changed = v:true
    endif
    if a:current_visible_line_end != l:previous_visible_line_end
        call setwinvar(a:winnr, 'previous_visible_line_end', a:current_visible_line_end)
        let l:viewport_changed = v:true
    endif
    call setwinvar(a:winnr, 'viewport_changed', l:viewport_changed)
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#utils#last_occurence_of_non_identifier
" Description:  Return the index of last occurence of non-identifier. E.g. ; or }
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#utils#last_occurence_of_non_identifier(str)
    let l:idx = -1
python << EOF
import vim
def is_identifier(char):
    is_digit = char.isdigit()
    is_alpha = char.isalpha()
    is_underscore = char == '_'
    return is_digit or is_alpha or is_underscore

string = vim.eval('a:str')
vim.command('let l:idx = %s' % str(-1))
for idx, char in enumerate(string[::-1]):
    if not is_identifier(char):
        vim.command('let l:idx = %s' % str(idx))
        break
EOF
    return l:idx
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#utils#statement_finished
" Description:  Deduce whether the statement is finished or not.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#utils#statement_finished(str)
    let l:last_char = a:str[len(a:str)-1]
    return l:last_char == ';' || l:last_char == '}'
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#utils#preview_open
" Description:  Open given filename at given (line, column) position in a pop-up floating window.
"               I scraped this impl somewhere from the web and tweaked a bit to accomodate my case
"               but can't remember exactly from where. Will give it credit if I do.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#utils#preview_open(filename, line, column)
    let bufnr = bufadd(a:filename)
    let wininfo = getwininfo(win_getid())[0]
    let space_above = &lines - line('.') + 1
    let space_below = line('.')
    let lnum = a:line
    let firstline = a:line - s:preview_win_get('offset') < 1 ? 1 : a:line - s:preview_win_get('offset')
    let height = s:preview_win_get('height')

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
            \   'close': s:preview_win_get('mouseclick'),
            \   'padding': [0,1,1,1],
            \   'border': [1,0,0,0],
            \   'borderchars': [' '],
            \   'moved': 'any',
            \   'mapping': v:false,
            \   'filter': funcref('s:preview_win_popup_filter', [firstline]),
            \   'filtermode': 'n',
            \   'highlight': 'QfPreview',
            \   'scrollbar': s:preview_win_get('scrollbar'),
            \   'borderhighlight': ['QfPreviewTitle'],
            \   'scrollbarhighlight': 'QfPreviewScrollbar',
            \   'thumbhighlight': 'QfPreviewThumb',
            \   'callback': {... -> !empty(s:preview_win_get('sign'))
            \     ? [sign_unplace('PopUpQfPreview'), sign_undefine('QfErrorLine')]
            \     : 0
            \   }
            \ })))

    " Set firstline to zero to prevent jumps when calling win_execute() #4876
    call popup_setoptions(winid, {'firstline': 0})
    call setwinvar(winid, '&number', !!s:preview_win_get('number'))

    if !empty(s:preview_win_get('sign')->get('text', ''))
        call setwinvar(winid, '&signcolumn', 'number')
    endif

    if !empty(s:preview_win_get('sign'))
        call sign_define('QfErrorLine', s:preview_win_get('sign'))
        call sign_place(0, 'PopUpQfPreview', 'QfErrorLine', bufnr, {'lnum': lnum})
    endif

    return winid
endfunction

let s:preview_win_defaults = {
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

let s:preview_win_get = {x -> get(b:, 'qfpreview', get(g:, 'qfpreview', {}))->get(x, s:preview_win_defaults[x])}

function! s:preview_win_set_height(winid, step) abort
    let height = popup_getoptions(a:winid).minheight
    let newheight = height + a:step > 0 ? height + a:step : 1
    call popup_setoptions(a:winid, {'minheight': newheight, 'maxheight': newheight})
    if !empty(s:preview_win_get('sign')->get('text', ''))
        call setwinvar(a:winid, '&signcolumn', 'number')
    endif
endfunction

function! s:preview_win_popup_filter(line, winid, key) abort
    if a:key ==# s:preview_win_get('scrollup')
        call win_execute(a:winid, "normal! \<c-y>")
    elseif a:key ==# s:preview_win_get('scrolldown')
        call win_execute(a:winid, "normal! \<c-e>")
    elseif a:key ==# s:preview_win_get('halfpageup')
        call win_execute(a:winid, "normal! \<c-u>")
    elseif a:key ==# s:preview_win_get('halfpagedown')
        call win_execute(a:winid, "normal! \<c-d>")
    elseif a:key ==# s:preview_win_get('fullpageup')
        call win_execute(a:winid, "normal! \<c-b>")
    elseif a:key ==# s:preview_win_get('fullpagedown')
        call win_execute(a:winid, "normal! \<c-f>")
    elseif a:key ==# s:preview_win_get('close')
        call popup_close(a:winid)
    elseif a:key ==# 'g'
        call win_execute(a:winid, 'normal! gg')
    elseif a:key ==# 'G'
        call win_execute(a:winid, 'normal! G')
    elseif a:key ==# '+'
        call s:preview_win_set_height(a:winid, 1)
    elseif a:key ==# '-'
        call s:preview_win_set_height(a:winid, -1)
    elseif a:key ==# 'r'
        call popup_setoptions(a:winid, {'firstline': a:line})
        call popup_setoptions(a:winid, {'firstline': 0})
        " Note: after popup_setoptions() 'signcolumn' needs to be reset again
        if !empty(s:preview_win_get('sign')->get('text', ''))
            call setwinvar(a:winid, '&signcolumn', 'number')
        endif
    else
        return v:false
    endif
    return v:true
endfunction
