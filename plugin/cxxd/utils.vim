" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#utils#serialize_current_buffer_contents
" Description:  Function which serializes current buffer contents to the given filename.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#utils#serialize_current_buffer_contents(to_filename)
python << EOF
import vim
temp_file = open(vim.eval('a:to_filename'), "w", 0)
temp_file.writelines(line + '\n' for line in vim.current.buffer)
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
    if !exists('w:previous_num_of_changes')     | let w:previous_num_of_changes     = 0       | endif
    if !exists('w:previous_visible_line_begin') | let w:previous_visible_line_begin = 0       | endif
    if !exists('w:previous_visible_line_end')   | let w:previous_visible_line_end   = 0       | endif
    if !exists('w:more_modifications_done')     | let w:more_modifications_done     = v:false | endif
    if !exists('w:viewport_changed')            | let w:viewport_changed            = v:false | endif
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#utils#is_more_modifications_done
" Description:  Check if more modifications has been done in given window.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#utils#is_more_modifications_done(winnr)
    return getwinvar(a:winnr, 'more_modifications_done')
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#utils#is_viewport_changed
" Description:  Check if viewport has been changed for given window.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#utils#is_viewport_changed(winnr)
    return getwinvar(a:winnr, 'viewport_changed')
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
	" 	1. CursorHold(I) events can be triggered by moving the cursor horizontally
	" 		* In which case we will report back that viewport
    " 		  hasn't been changed
	" 	2. CursorHold(I) events can be triggered by moving cursor vertically
	" 	   but not enough to change the viewport (i.e. moving cursor across
	" 	   the lines but without changing the first and last line visible
    " 	   in the given window)
	" 	   	* In which case we will still report back that viewport
	" 	   	  hasn't been changed
	" 	3. CursorHold(I) events can be triggered by moving cursor vertically
	" 	   but this time enough to impact the viewport (i.e. move
	" 	   cursor upwards when we are at the top of the viewport or
	" 	   move cursor downwards when we are the bottom of the
	" 	   viewport)
	" 	   	* In which case we will report back that viewport
	" 	   	  has been changed
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
" Description:  Find.
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

