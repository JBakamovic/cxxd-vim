import logging
import os
import tempfile
from utils import Utils
from cxxd.service_plugin import ServicePlugin
from cxxd.services.disassembly_service import DisassemblyRequestId

class VimDisassembly(ServicePlugin):
    def __init__(self, servername):
        self.servername = servername
        self.disassembly_target_candidates_output = os.path.join(tempfile.gettempdir(), self.servername + 'disassembly_target_candidates')
        self.disassembly_symbol_candidates_output = os.path.join(tempfile.gettempdir(), self.servername + 'disassembly_symbol_candidates')

    def startup_callback(self, success, payload, startup_payload):
        Utils.call_vim_remote_function(self.servername, "cxxd#services#disassembly#start_callback(" + str(int(success)) + ")")

    def shutdown_callback(self, success, payload, shutdown_payload):
        reply_with_callback = bool(payload[0])
        if reply_with_callback:
            Utils.call_vim_remote_function(self.servername, "cxxd#services#disassembly#stop_callback(" + str(int(success)) + ")")

    def __call__(self, success, payload, args):
        disassembly_op_id = int(payload[0])
        if disassembly_op_id == DisassemblyRequestId.LIST_TARGETS:
            self._list_targets(success, payload, args)
        elif disassembly_op_id == DisassemblyRequestId.LIST_SYMBOL_CANDIDATES:
            self._list_symbol_candidates(success, payload, args)
        elif disassembly_op_id == DisassemblyRequestId.DISASSEMBLE:
            self._disassemble(success, payload, args)
        elif disassembly_op_id == DisassemblyRequestId.ASM_INSTRUCTION_INFO:
            self._info_on_asm_instruction(success, payload, args)
        else:
            logging.error('Invalid disassembly request ID: {0}'.format(disassembly_op_id))

    def _list_targets(self, success, payload, args):
        target_candidates = args
        with open(self.disassembly_target_candidates_output, 'w') as f:
            f.writelines(', '.join(str("'" + item.strip() + "'") for item in target_candidates))
        Utils.call_vim_remote_function(
            self.servername,
            "cxxd#services#disassembly#pick_target_callback(" + str(int(success)) + ", '" + str(self.disassembly_target_candidates_output) + "', " + str(len(target_candidates)) + ")"
        )

    def _list_symbol_candidates(self, success, payload, args):
        def make_popup_item(symbol):
            return symbol.demangled_name + ' ' + \
                symbol.type + ' ' + \
                symbol.addr + ' ' + \
                symbol.offset + ' ' + \
                symbol.location

        symbol_candidates = args
        with open(self.disassembly_symbol_candidates_output, 'w') as f:
            f.writelines(', '.join(str("'" + make_popup_item(item) + "'") for item in symbol_candidates))
        Utils.call_vim_remote_function(
            self.servername,
            "cxxd#services#disassembly#pick_symbol_callback(" + str(int(success)) + ", '" + str(self.disassembly_symbol_candidates_output) + "', " + str(len(symbol_candidates)) + ")"
        )

    def _disassemble(self, success, payload, args):
        disassembly_output, addr, offset = args
        Utils.call_vim_remote_function(
            self.servername,
            "cxxd#services#disassembly#run_callback(" + str(int(success)) + ", '" + str(disassembly_output) + "', '" + str(addr) + "', '" + str(offset) + "')"
        )

    def _info_on_asm_instruction(self, success, payload, args):
        tooltip = args[0]
        description = args[1]
        url = args[2]
        Utils.call_vim_remote_function(
            self.servername,
            "cxxd#services#disassembly#asm_instruction_info_callback(" + str(int(success)) + ", '" + str(tooltip) + "', '" + str(description) + "', '" + str(url) + "')"
        )
