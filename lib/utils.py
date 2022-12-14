import socket
from subprocess import call
import shlex

file_type_dict = {
    'Cxx': ['.c', '.cpp', '.cc', '.h', '.hh', '.hpp'],
    'Java': ['.java'] }

class Utils():
    @staticmethod
    def file_type_to_programming_language(file_type):
        for lang, file_types in file_type_dict.items():
            if file_type in file_types:
                return lang
        return ''

    @staticmethod
    def programming_language_to_extension(programming_language):
        return file_type_dict.get(programming_language, '')

    @staticmethod
    def send_vim_remote_command(vim_instance, command):
        cmd = 'gvim --servername ' + vim_instance + ' --remote-send "<ESC>' + command + '<CR>"'
        return call(shlex.split(cmd))

    @staticmethod
    def call_vim_remote_function(vim_instance, function):
        cmd = 'gvim --servername ' + vim_instance + ' --remote-expr "' + function + '"'
        return call(shlex.split(cmd))

    @staticmethod
    def is_port_available(port):
        s = socket.socket()
        try:
            s.bind(('localhost', port))
            s.close()
            return True
        except socket.error as msg:
            s.close()
            return False

    @staticmethod
    def get_available_port(port_begin, port_end):
        for port in range(port_begin, port_end):
            if Utils.is_port_available(port) == True:
                return port
        return -1
