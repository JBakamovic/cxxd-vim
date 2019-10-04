from builtins import str
from builtins import object
import logging
from utils import Utils

class VimGoToDefinition(object):
    def __init__(self, servername):
        self.servername = servername

    def __call__(self, success, payload, definition):
        def call_vim_rpc(status, filename, line, column):
            Utils.call_vim_remote_function(
                self.servername,
                "cxxd#services#source_code_model#go_to_definition#run_callback(" + str(int(status)) + ", '" + filename + "', " + str(line) + ", " + str(column) + ")"
            )

        if success:
            filename, line, column = definition
            call_vim_rpc(success, filename, line, column)
            logging.info('Definition found at {0} [{1}, {2}]'.format(filename, line, column))
        else:
            call_vim_rpc(success, '', 0, 0)
            logging.error('Something went wrong in go-to-definition service ... Definition not found. Payload = {0}'.format(payload))
