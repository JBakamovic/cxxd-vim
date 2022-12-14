import logging
import os
import tempfile
from utils import Utils
from cxxd.parser.ast_node_identifier import ASTNodeId
from cxxd.parser.clang_parser import ClangParser
from cxxd.service_plugin import ServicePlugin
from cxxd.services.code_completion.code_completion import CodeCompletionRequestId

class VimCodeCompletion(ServicePlugin):
    def __init__(self, servername):
        self.servername = servername
        self.code_complete_candidates_output = os.path.join(tempfile.gettempdir(), self.servername + 'code_complete_candidates')

    def _create_vim_complete_item(self, candidate, detailed_candidate, kind, result_type, extra_documentation = None):
        return {
            'word' : candidate,             # On item selection, insert shortened form of the candidate (e.g. function without parameters)
            'abbr' : detailed_candidate,    # But still show detailed information about the candidate when available (e.g. function arguments)
            'kind' : kind,
            'menu' : result_type if result_type else '',
            'info' : extra_documentation if extra_documentation else '',
            'dup'  : 1,                     # Function overloads, e.g. push_back(const value_type&&) and push_back(value_type&&),
                                            # will result in 'word' duplicates (e.g. multiple push_back's).
                                            # As duplicate 'word's will not be added by default, we must set this
                                            # property in order to preserve all of the overloads in the list.
        }

    def _extract_chunks(self, completion_string):
        # TODO handle isKindOptional, isKindInformative and others which make sense
        result_type, candidate, params = None, None, []
        for chunk in completion_string:
            if chunk.isKindTypedText():
                candidate = chunk.spelling
            elif chunk.isKindResultType():
                result_type = chunk.spelling
            elif chunk.isKindPlaceHolder():
                params.append(chunk.spelling)
        return result_type, candidate, params

    def _ast_node_id_to_vim_complete_item_kind(self, ast_node_id):
        # Vim does not have support for all of the kinds we are able to identify with clang, so we do
        # our best to map those remaining in the best category.

        # 'n' namespace (NOTE: not really supported according to :help complete-items but shows up nicely in pum)
        if ast_node_id in [\
            ASTNodeId.getNamespaceId(),
            ASTNodeId.getNamespaceAliasId()]:
            return 'n'

        # 'v' variable
        if ast_node_id in [\
            ASTNodeId.getLocalVariableId(),
            ASTNodeId.getFunctionParameterId(),
            ASTNodeId.getTemplateTypeParameterId(),
            ASTNodeId.getTemplateNonTypeParameterId(),
            ASTNodeId.getTemplateTemplateParameterId()]:
            return 'v'

        # 'f' function or method
        if ast_node_id in [\
            ASTNodeId.getFunctionId(),
            ASTNodeId.getMethodId()]:
            return 'f'

        # 'm' member of a struct or class
        if ast_node_id in [\
            ASTNodeId.getClassId(),
            ASTNodeId.getStructId(),
            ASTNodeId.getEnumId(),
            ASTNodeId.getEnumValueId(),
            ASTNodeId.getUnionId(),
            ASTNodeId.getFieldId()]:
            return 'm'

        # 't' typedef
        if ast_node_id in [\
            ASTNodeId.getTypedefId()]:
            return 't'

        # 'd' #define or macro
        if ast_node_id in [\
            ASTNodeId.getMacroInstantiationId(),
            ASTNodeId.getMacroDefinitionId()]:
            return 'd'

        # Otherwise we return an empty Vim kind
        logging.error("Unable to map AST node id '{0}' to available Vim kinds!".format(ast_node_id))
        return ''

    def startup_callback(self, success, payload, startup_payload):
        Utils.call_vim_remote_function(self.servername, "cxxd#services#code_completion#start_callback(" + str(int(success)) + ")")

    def shutdown_callback(self, success, payload, shutdown_payload):
        reply_with_callback = bool(payload[0])
        if reply_with_callback:
            Utils.call_vim_remote_function(self.servername, "cxxd#services#code_completion#stop_callback(" + str(int(success)) + ")")

    def __call__(self, success, payload, code_completion_results):
        if not success:
            logging.error('Something went wrong in code-completion service ... Payload = {0}'.format(payload))

        code_completion_op_id = int(payload[0])
        if code_completion_op_id == CodeCompletionRequestId.CODE_COMPLETE:
            self.__code_complete(success, payload, code_completion_results)
        elif code_completion_op_id == CodeCompletionRequestId.CACHE_WARMUP:
            self.__cache_warmup(success, payload, code_completion_results)
        else:
            logging.error('Invalid code-completion request ID: {0}'.format(code_completion_op_id))

    def __cache_warmup(self, success, payload, code_completion_results):
        logging.info('Warming up the code-completion cache done')

    def __code_complete(self, success, payload, code_completion_results):
        def call_vim_rpc(status, completion_candidates, length):
            Utils.call_vim_remote_function(
                self.servername,
                "cxxd#services#code_completion#run_callback(" + str(int(status)) + ", '" + str(completion_candidates) + "', " + str(length) + ")"
            )

        if success:
            candidate_list = []
            for result in code_completion_results:
                kind = self._ast_node_id_to_vim_complete_item_kind(ClangParser.to_ast_node_id(result.kind))
                if kind != '':
                    result_type, candidate, params = self._extract_chunks(result.string)
                    if candidate:
                        candidate_list.append(
                            self._create_vim_complete_item(
                                candidate + '(' + ')' if kind == 'f' else candidate,
                                candidate + '(' + ', '.join(params) + ')' if kind == 'f' else candidate,
                                kind,
                                result_type
                            )
                        )
                else:
                    logging.error('Cannot handle following cursor kind: {0}'.format(result.kind))

            with open(self.code_complete_candidates_output, 'w', 0) as f:
                f.writelines(', '.join(str(item) for item in candidate_list))

            call_vim_rpc(success, self.code_complete_candidates_output, len(candidate_list))
            logging.info('Found {0} candidates.'.format(len(candidate_list)))
        else:
            call_vim_rpc(success, [], 0)
