import logging
from utils import Utils

class VimAutoCompletion():
    def __init__(self, servername):
        self.servername = servername

    def __call__(self, success, payload, code_completion_result):
        def call_vim_rpc(status, completion_candidates):
            Utils.call_vim_remote_function(
                self.servername,
                "cxxd#services#source_code_model#auto_completion#run_callback(" + str(int(status)) + ", " + str(completion_candidates) + ")"
            )

        if success:
            candidate_list = []
            for result in code_completion_result:
                completion_string = ''
                for chunk in result.string:
                    completion_string += chunk.spelling + ' '
                candidate_list.append(completion_string)
            for candidate in candidate_list:
                logging.info('{0}'.format(candidate))
            call_vim_rpc(success, candidate_list)
        else:
            call_vim_rpc(success, [])
            logging.error('Something went wrong in auto-completion service ... Payload = {0}'.format(payload))
