from builtins import str
import logging
from utils import Utils
from cxxd.service_plugin import ServicePlugin

class VimDisassembly(ServicePlugin):
    def __init__(self, servername):
        self.servername = servername

    def startup_callback(self, success, payload, startup_payload):
        Utils.call_vim_remote_function(self.servername, "cxxd#services#disassembly#start_callback(" + str(int(success)) + ")")

    def shutdown_callback(self, success, payload, shutdown_payload):
        reply_with_callback = bool(payload[0])
        if reply_with_callback:
            Utils.call_vim_remote_function(self.servername, "cxxd#services#disassembly#stop_callback(" + str(int(success)) + ")")

    def __call__(self, success, payload, disassembly_output):
        def call_vim_rpc(status, filename, disassembly_output):
            Utils.call_vim_remote_function(
                self.servername,
                "cxxd#services#disassembly#run_callback(" + str(int(status)) + ", '" + filename + "', '" + disassembly_output + "')"
            )

        if success:
            call_vim_rpc(success, payload[1], disassembly_output)
        else:
            call_vim_rpc(success, payload[1], '')
            logging.error("Something went wrong with disassembly ... success={0}, payload={1}, args={2}.".format(success, payload, disassembly_output))
