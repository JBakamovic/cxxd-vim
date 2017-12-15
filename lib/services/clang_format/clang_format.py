import logging
from utils import Utils
from cxxd.service_plugin import ServicePlugin

class VimClangFormat(ServicePlugin):
    def __init__(self, servername):
        self.servername = servername

    def startup_callback(self, success, payload):
        Utils.call_vim_remote_function(self.servername, "cxxd#services#clang_format#start_callback(" + str(int(success)) + ")")

    def shutdown_callback(self, success, payload):
        reply_with_callback = bool(payload[0])
        if reply_with_callback:
            Utils.call_vim_remote_function(self.servername, "cxxd#services#clang_format#stop_callback(" + str(int(success)) + ")")

    def __call__(self, success, payload, args):
        if not success:
            logging.error("Something went wrong with clang-format ... success={0}, payload={1}, args={2}.".format(success, payload, args))
        Utils.call_vim_remote_function(self.servername, "cxxd#services#clang_format#run_callback(" + str(int(success)) + ", '" + payload[0] + "')")
