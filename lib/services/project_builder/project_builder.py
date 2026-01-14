import logging
from utils import Utils
from cxxd.service_plugin import ServicePlugin

class VimProjectBuilder(ServicePlugin):
    def __init__(self, servername):
        self.servername = servername

    def startup_callback(self, success, payload, startup_payload):
        Utils.call_vim_remote_function("cxxd#services#project_builder#start_callback(" + str(int(success)) + ")")

    def shutdown_callback(self, success, payload, shutdown_payload):
        reply_with_callback = bool(payload[0])
        if reply_with_callback:
            Utils.call_vim_remote_function("cxxd#services#project_builder#stop_callback(" + str(int(success)) + ")")

    def __call__(self, success, payload, args):
        request_id = int(payload[0])

        if request_id == 0x0: # LIST_TARGETS
            # args is the list of targets
            targets_str = str(args).replace("'", '"')
            Utils.call_vim_remote_function(
                "cxxd#services#project_builder#pick_target_callback(" + str(int(success)) + ", " + targets_str + ")"
            )
            return

        def call_vim_rpc(status, cmd):
            Utils.call_vim_remote_function(
                "cxxd#services#project_builder#on_build_command_received(" + str(int(status)) + ", '" + cmd + "')"
            )

        if success:
            command_string = args[0]
            call_vim_rpc(success, command_string)
        else:
            logging.error("Something went wrong with project-builder ... success={0}, payload={1}, args={2}.".format(success, payload, args))
            call_vim_rpc(success, '')
