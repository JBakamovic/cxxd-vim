import logging
import os
import tempfile
from cxxd.services.source_code_model.indexer.clang_indexer import SourceCodeModelIndexerRequestId
from utils import Utils

class VimIndexer(object):
    def __init__(self, servername):
        self.servername = servername
        self.find_all_references_output = os.path.join(tempfile.gettempdir(), self.servername + 'find_all_references')
        self.op = {
            SourceCodeModelIndexerRequestId.RUN_ON_SINGLE_FILE  : self.__run_on_single_file,
            SourceCodeModelIndexerRequestId.RUN_ON_DIRECTORY    : self.__run_on_directory,
            SourceCodeModelIndexerRequestId.DROP_SINGLE_FILE    : self.__drop_single_file,
            SourceCodeModelIndexerRequestId.DROP_ALL            : self.__drop_all,
            SourceCodeModelIndexerRequestId.FIND_ALL_REFERENCES : self.__find_all_references
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
