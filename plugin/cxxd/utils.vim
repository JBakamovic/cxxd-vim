function! cxxd#utils#serialize_current_buffer_contents(to_filename)
python << EOF
import vim
temp_file = open(vim.eval('a:to_filename'), "w", 0)
temp_file.writelines(line + '\n' for line in vim.current.buffer)
EOF
endfunction

