import logging
import os

import json
from cxxd.services.source_code_model.indexer.clang_indexer import SourceCodeModelIndexerRequestId
from utils import Utils

class VimIndexer:
    def __init__(self, servername):
        self.servername = servername
        self.op = {
            SourceCodeModelIndexerRequestId.RUN_ON_SINGLE_FILE    : self.__run_on_single_file,
            SourceCodeModelIndexerRequestId.RUN_ON_DIRECTORY      : self.__run_on_directory,
            SourceCodeModelIndexerRequestId.DROP_SINGLE_FILE      : self.__drop_single_file,
            SourceCodeModelIndexerRequestId.DROP_ALL              : self.__drop_all,
            SourceCodeModelIndexerRequestId.FIND_ALL_REFERENCES   : self.__find_all_references,
            SourceCodeModelIndexerRequestId.FETCH_ALL_DIAGNOSTICS : self.__fetch_all_diagnostics,
            SourceCodeModelIndexerRequestId.FETCH_ALL_DEFINITIONS : self.__fetch_all_definitions,
        }

    def __call__(self, success, payload, args):
        self.op.get(int(payload[1]), self.__unknown_op)(success, args)

    def __unknown_op(self, success, args):
        logging.error("Unknown operation triggered! Valid operations are: {0}".format(self.op))

    def __run_on_single_file(self, success, args):
        Utils.call_vim_remote_function(
            "cxxd#services#source_code_model#indexer#run_on_single_file_callback(" + str(int(success)) + ")"
        )

    def __run_on_directory(self, success, args):
        Utils.call_vim_remote_function(
            "cxxd#services#source_code_model#indexer#run_on_directory_callback(" + str(int(success)) + ")"
        )

    def __drop_single_file(self, success, args):
        Utils.call_vim_remote_function(
            "cxxd#services#source_code_model#indexer#drop_single_file_callback(" + str(int(success)) + ")"
        )

    def __drop_all(self, success, args):
        Utils.call_vim_remote_function(
            "cxxd#services#source_code_model#indexer#drop_all_callback(" + str(int(success)) + ")"
        )

    def __find_all_references(self, success, references):
        quickfix_list = []
        for ref in references:
            filename, line, column, context = ref
            # Construct dictionary for JSON serialization
            quickfix_list.append({
                'filename': filename,
                'lnum': line,
                'col': column,
                'type': 'I',
                'text': context.rstrip()
            })

        json_references = json.dumps(quickfix_list)

        Utils.call_vim_remote_function(
            "cxxd#services#source_code_model#indexer#find_all_references_callback(" + str(int(success)) + ", " + json_references + ")"
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
            quickfix_list.append({
                'filename': filename,
                'lnum': line,
                'col': column,
                'type': clang_severity_to_quickfix_type(severity),
                'text': description.rstrip()
            })

        json_diagnostics = json.dumps(quickfix_list)

        Utils.call_vim_remote_function(
            "cxxd#services#source_code_model#indexer#fetch_all_diagnostics_callback(" + str(int(success)) + ", " + json_diagnostics + ")"
        )
        logging.debug("Diagnostics: " + str(quickfix_list))

    def __fetch_all_definitions(self, success, args):
        # args is [output_file_path]
        if args and len(args) > 0:
            output_file_path = args[0]
            Utils.call_vim_remote_function(
                "cxxd#services#source_code_model#indexer#fetch_all_definitions_callback(" + str(int(success)) + ", '" + output_file_path + "')"
            )
            logging.debug("Definitions streamed to: " + output_file_path)
        else:
            logging.error("Fetch all definitions failed or returned no path")
            Utils.call_vim_remote_function(
                "cxxd#services#source_code_model#indexer#fetch_all_definitions_callback(" + str(int(False)) + ", '')"
            )


