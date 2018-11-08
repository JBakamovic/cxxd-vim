import logging
import tempfile
import os
from utils import Utils
from cxxd.service_plugin import ServicePlugin
from cxxd.services.source_code_model_service import SourceCodeModelSubServiceId
from indexer.indexer import VimIndexer
from semantic_syntax_highlight.semantic_syntax_highlight import VimSemanticSyntaxHighlight
from diagnostics.diagnostics import VimDiagnostics
from type_deduction.type_deduction import VimTypeDeduction
from go_to_definition.go_to_definition import VimGoToDefinition
from go_to_include.go_to_include import VimGoToInclude

class VimSourceCodeModel(ServicePlugin):
    def __init__(self, servername):
        self.servername = servername
        self.indexer = VimIndexer(self.servername)
        self.semantic_syntax_higlight = VimSemanticSyntaxHighlight(self.servername, tempfile.gettempdir() + os.sep + self.servername + '_syntax_file.vim')
        self.diagnostics = VimDiagnostics(self.servername)
        self.type_deduction = VimTypeDeduction(self.servername)
        self.go_to_definition = VimGoToDefinition(self.servername)
        self.go_to_include = VimGoToInclude(self.servername)

    def startup_callback(self, success, payload):
        compiler_args_filename = payload[0]
        Utils.call_vim_remote_function(
            self.servername,
            "cxxd#services#source_code_model#start_callback(" + str(int(success)) + ")"
        )
        logging.info("SourceCodeModel configured with: compiler args='{0}'".format(compiler_args_filename))

    def shutdown_callback(self, success, payload):
        reply_with_callback = bool(payload[0])
        if reply_with_callback:
            Utils.call_vim_remote_function(
                self.servername,
                "cxxd#services#source_code_model#stop_callback(" + str(int(success)) + ")"
            )

    def __call__(self, success, payload, args):
        source_code_model_service_id = int(payload[0])
        if source_code_model_service_id == SourceCodeModelSubServiceId.INDEXER:
            self.indexer(success, payload, args)
        elif source_code_model_service_id == SourceCodeModelSubServiceId.SEMANTIC_SYNTAX_HIGHLIGHT:
            self.semantic_syntax_higlight(success, payload, args)
        elif source_code_model_service_id == SourceCodeModelSubServiceId.DIAGNOSTICS:
            self.diagnostics(success, payload, args)
        elif source_code_model_service_id == SourceCodeModelSubServiceId.TYPE_DEDUCTION:
            self.type_deduction(success, payload, args)
        elif source_code_model_service_id == SourceCodeModelSubServiceId.GO_TO_DEFINITION:
            self.go_to_definition(success, payload, args)
        elif source_code_model_service_id == SourceCodeModelSubServiceId.GO_TO_INCLUDE:
            self.go_to_include(success, payload, args)
        else:
            logging.error('Invalid source code model service id!')
