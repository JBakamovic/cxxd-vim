from builtins import str
from builtins import object
import logging
import os
import tempfile
from cxxd.services.source_code_model.indexer.clang_indexer import SourceCodeModelIndexerRequestId
from utils import Utils

class VimIndexer(object):
    def __init__(self, servername):
        self.servername = servername
        self.find_all_references_output = os.path.join(tempfile.gettempdir(), self.servername + 'find_all_references')
        self.fetch_all_diagnostics_output = os.path.join(tempfile.gettempdir(), self.servername + 'fetch_all_diagnostics')
        self.op = {
            SourceCodeModelIndexerRequestId.RUN_ON_SINGLE_FILE    : self.__run_on_single_file,
            SourceCodeModelIndexerRequestId.RUN_ON_DIRECTORY      : self.__run_on_directory,
            SourceCodeModelIndexerRequestId.DROP_SINGLE_FILE      : self.__drop_single_file,
            SourceCodeModelIndexerRequestId.DROP_ALL              : self.__drop_all,
            SourceCodeModelIndexerRequestId.FIND_ALL_REFERENCES   : self.__find_all_references,
            SourceCodeModelIndexerRequestId.FETCH_ALL_DIAGNOSTICS : self.__fetch_all_diagnostics,
        }

    def __call__(self, success, payload, args):
        self.op.get(int(payload[1]), self.__unknown_op)(success, args)

    def __unknown_op(self, success, args):
        logging.error("Unknown operation triggered! Valid operations are: {0}".format(self.op))

    def __run_on_single_file(self, success, args):
        Utils.call_vim_remote_function(
            self.servername,
            "cxxd#services#source_code_model#indexer#run_on_single_file_callback(" + str(int(success)) + ")"
        )

    def __run_on_directory(self, success, args):
        Utils.call_vim_remote_function(
            self.servername,
            "cxxd#services#source_code_model#indexer#run_on_directory_callback(" + str(int(success)) + ")"
        )

    def __drop_single_file(self, success, args):
        Utils.call_vim_remote_function(
            self.servername,
            "cxxd#services#source_code_model#indexer#drop_single_file_callback(" + str(int(success)) + ")"
        )

    def __drop_all(self, success, args):
        Utils.call_vim_remote_function(
            self.servername, "cxxd#services#source_code_model#indexer#drop_all_callback(" + str(int(success)) + ")"
        )

    def __find_all_references(self, success, references):
        quickfix_list = []
        for ref in references:
            filename, line, column, context = ref
            quickfix_list.append(
                "{'filename': '" + filename + "', " +
                "'lnum': '" + str(line) + "', " +
                "'col': '" + str(column) + "', " +
                "'type': 'I', " +
                "'text': '" + context.replace("'", r"''").rstrip() + "'}"
            )

        with open(self.find_all_references_output, 'w', 0) as f:
            f.writelines(', '.join(item for item in quickfix_list))

        Utils.call_vim_remote_function(
            self.servername,
            "cxxd#services#source_code_model#indexer#find_all_references_callback(" + str(int(success)) + ", '" + self.find_all_references_output + "')"
        )
        logging.debug("References: " + str(quickfix_list))

    def __fetch_all_diagnostics(self, success, diagnostics):
        def clang_severity_to_quickfix_type(severity):
            # Clang severity | Vim Quickfix type
            # ----------------------------------
            #   Ignored = 0     I (info)
            #   Note    = 1     I (info)
            #   Warning = 2     W (warning)
            #   Error   = 3     E (error)
            #   Fatal   = 4     E (error)
            # ----------------------------------
            if severity == 0:
                return 'I'
            elif severity == 1:
                return 'I'
            elif severity == 2:
                return 'W'
            elif severity >= 3:
                return 'E'
            return '0'

        quickfix_list = []
        for diag in diagnostics:
            filename, line, column, description, severity = diag
            quickfix_list.append(
                "{'filename': '" + filename + "', " +
                "'lnum': '" + str(line) + "', " +
                "'col': '" + str(column) + "', " +
                "'type': '" + clang_severity_to_quickfix_type(severity) + "', " +
                "'text': '" + description.replace("'", r"''").rstrip() + "'}"
            )

        with open(self.fetch_all_diagnostics_output, 'w', 0) as f:
            f.writelines(', '.join(item for item in quickfix_list))

        Utils.call_vim_remote_function(
            self.servername,
            "cxxd#services#source_code_model#indexer#fetch_all_diagnostics_callback(" + str(int(success)) + ", '" + self.fetch_all_diagnostics_output + "')"
        )
        logging.debug("Diagnostics: " + str(quickfix_list))
