from builtins import str
from builtins import object
import logging
from utils import Utils

class VimGoToInclude(object):
    def __init__(self, servername):
        self.servername = servername

    def __call__(self, success, payload, include):
        def call_vim_rpc(status, include):
            Utils.call_vim_remote_function(
                self.servername,
                "cxxd#services#source_code_model#go_to_include#run_callback(" + str(int(status)) + ", '" + include + "')"
            )

        if success:
            call_vim_rpc(success, include)
            logging.info("Include filename={0}".format(include))
        else:
            call_vim_rpc(success, '')
            logging.error('Something went wrong in go-to-include service ... Include not found. Payload={0}'.format(payload))
