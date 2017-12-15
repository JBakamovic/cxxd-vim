import logging
from utils import Utils
from cxxd.service_plugin import ServicePlugin

class VimProjectBuilder(ServicePlugin):
    def __init__(self, servername):
        self.servername = servername

    def startup_callback(self, success, payload):
        Utils.call_vim_remote_function(self.servername, "cxxd#services#project_builder#start_callback(" + str(int(success)) + ")")

    def shutdown_callback(self, success, payload):
        reply_with_callback = bool(payload[0])
        if reply_with_callback:
            Utils.call_vim_remote_function(self.servername, "cxxd#services#project_builder#stop_callback(" + str(int(success)) + ")")

    def __call__(self, success, payload, args):
        def call_vim_rpc(status, duration, build_exit_code, output):
            Utils.call_vim_remote_function(
                self.servername,
                "cxxd#services#project_builder#run_callback(" + str(int(status)) + ", '" + str(duration) + "', " + str(build_exit_code) + ", '" + output + "')"
            )

        if success:
            output, build_exit_code, duration = args
            call_vim_rpc(success, duration, build_exit_code, output)
        else:
            logging.error("Something went wrong with project-builder ... success={0}, payload={1}, args={2}.".format(success, payload, args))
            call_vim_rpc(success, 0, 0, '')
