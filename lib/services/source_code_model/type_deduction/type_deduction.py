from builtins import str
from builtins import object
import logging
from utils import Utils

class VimTypeDeduction(object):
    def __init__(self, servername):
        self.servername = servername

    def __call__(self, success, payload, type_spelling):
        def call_vim_rpc(status, type_spelling):
            Utils.call_vim_remote_function(
                self.servername,
                "cxxd#services#source_code_model#type_deduction#run_callback(" + str(int(status)) + ", '" + type_spelling + "')"
            )

        if success:
            logging.debug("Type spelling={0}".format(type_spelling))
            call_vim_rpc(success, type_spelling)
        else:
            call_vim_rpc(success, '')
            logging.error('Something went wrong in type deduction service ... Type has not been successfuly deducted. Payload={0}'.format(payload))
