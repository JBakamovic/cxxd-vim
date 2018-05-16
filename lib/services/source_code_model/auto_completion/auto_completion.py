import logging
from utils import Utils

class VimAutoCompletion():
    def __init__(self, servername):
        self.servername = servername

    def _create_vim_complete_item(self, candidate, kind, return_type = None, extra_documentation = None):
        return {'word' : candidate, 'kind' : kind, 'menu' : return_type if return_type else '', 'info' : extra_documentation if extra_documentation is not None else ''}

    def _extract_chunks(self, completion_string):
        # TODO handle isKindOptional, isKindInformative and others which make sense
        return_type, candidate, params = None, None, []
        for chunk in completion_string:
            if chunk.isKindTypedText():
                candidate = chunk.spelling
            elif chunk.isKindResultType():
                return_type = chunk.spelling
            elif chunk.isKindPlaceHolder():
                params.append(chunk.spelling)
        return return_type, candidate, params

    def _extract_result_kind(self, result):
        # TODO Implement support for different kinds
        # 'v' variable
        # 'm' struct/class member
        # 't' typedef
        # 'd' define/macro
        return 'f'

    def __call__(self, success, payload, code_completion_result):
        def call_vim_rpc(status, completion_candidates):
            Utils.call_vim_remote_function(
                self.servername,
                "cxxd#services#source_code_model#auto_completion#run_callback(" + str(int(status)) + ", " + str(completion_candidates) + ")"
            )

        if success:
            candidate_list = []
            for result in code_completion_result:
                kind = self._extract_result_kind(result)
                return_type, candidate, params = self._extract_chunks(result.string)
                candidate_list.append(
                    self._create_vim_complete_item(
                        candidate + ' (' + ', '.join(params) + ')' if kind == 'f' else candidate,
                        kind,
                        return_type
                    )
                )
            call_vim_rpc(success, candidate_list)
            logging.info('Found {0} candidates.'.format(len(candidate_list)))
        else:
            call_vim_rpc(success, [])
            logging.error('Something went wrong in auto-completion service ... Payload = {0}'.format(payload))
