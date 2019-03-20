" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Our Python path has to include a parent directory of 'cxxd' submodule.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
python import os, sys, vim
python sys.path.append(vim.eval("fnamemodify(fnamemodify(expand('<sfile>:p:h'), ':h'), ':h')") + os.sep + 'lib')

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Our public interface to cxxd.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
python import cxxd.api

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" We need a handle to server to establish the communication.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
python server_handle = None

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#server#start()
" Description:  Starts cxxd server.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#server#start(project_root_directory, ...)
    let l:project_root_directory_full_path =  fnamemodify(a:project_root_directory, ':p')
    let l:target_configuration = ''         " auto-discovery mode by default
    if a:0 > 0
        let l:target_configuration = a:1    " otherwise what user has provided to us
    endif
python << EOF
import os
import tempfile
import vim
import server
vim_server_name = vim.eval('v:servername')
server_handle = cxxd.api.server_start(
    server.get_instance,
    vim_server_name,
    vim.eval('l:project_root_directory_full_path'),
    vim.eval('l:target_configuration'),
    tempfile.gettempdir() + os.sep + vim_server_name + '_server.log'
)
EOF
    call cxxd#server#start_all_services()
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#server#stop()
" Description:  Stops cxxd server.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#server#stop(subscribe_for_shutdown_callback)
    python cxxd.api.server_stop(server_handle, vim.eval('a:subscribe_for_shutdown_callback'))
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#server#start_all_services()
" Description:  Starts all cxxd server services.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#server#start_all_services()
    call cxxd#services#source_code_model#start()
    call cxxd#services#clang_tidy#start()
    call cxxd#services#clang_format#start()
    call cxxd#services#project_builder#start()
    call cxxd#services#source_code_model#auto_completion#start()
endfunction

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Function:     cxxd#server#stop_all_services()
" Description:  Stops all cxxd server services.
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! cxxd#server#stop_all_services(subscribe_for_shutdown_callback)
    call cxxd#services#source_code_model#stop(a:subscribe_for_shutdown_callback)
    call cxxd#services#clang_tidy#stop(a:subscribe_for_shutdown_callback)
    call cxxd#services#clang_format#stop(a:subscribe_for_shutdown_callback)
    call cxxd#services#project_builder#stop(a:subscribe_for_shutdown_callback)
    call cxxd#services#source_code_model#auto_completion#stop(a:subscribe_for_shutdown_callback)
endfunction
