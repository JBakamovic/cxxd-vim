import json
import sys

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
    def call_vim_remote_function(function):
        try:
            msg = {"exec": "call " + function}
            sys.stdout.write(json.dumps(msg) + "\n")
            sys.stdout.flush()
        except Exception as e:
            pass
        return
