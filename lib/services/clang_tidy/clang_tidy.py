import logging
from utils import Utils
from cxxd.service_plugin import ServicePlugin

class VimClangTidy(ServicePlugin):
    def __init__(self, servername):
        self.servername = servername

    def startup_callback(self, success, payload, startup_payload):
        Utils.call_vim_remote_function(self.servername, "cxxd#services#clang_tidy#start_callback(" + str(int(success)) + ")")

    def shutdown_callback(self, success, payload, shutdown_payload):
        reply_with_callback = bool(payload[0])
        if reply_with_callback:
            Utils.call_vim_remote_function(self.servername, "cxxd#services#clang_tidy#stop_callback(" + str(int(success)) + ")")

    def __call__(self, success, payload, clang_tidy_output):
        def call_vim_rpc(status, filename, fixes_applied, clang_tidy_output):
            Utils.call_vim_remote_function(
                self.servername,
                "cxxd#services#clang_tidy#run_callback(" + str(int(status)) + ", '" + filename + "', " + str(int(fixes_applied)) + ", '" + clang_tidy_output + "')"
            )

        if success:
            call_vim_rpc(success, payload[0], payload[1], clang_tidy_output)
        else:
            call_vim_rpc(success, payload[0], payload[1], '')
            logging.error("Something went wrong with clang-tidy ... success={0}, payload={1}, args={2}.".format(success, payload, clang_tidy_output))
