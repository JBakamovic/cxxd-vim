from builtins import str
from builtins import object
import logging
from utils import Utils

class VimDiagnostics(object):
    def __init__(self, servername):
        self.servername = servername

    def __call__(self, success, payload, args):
        def clang_severity_to_quickfix_type(severity):
            # Clang severity | Vim Quickfix type
            # ----------------------------------
            #   Ignored = 0     I (info)
            #   Note    = 1     I (info)
            #   Warning = 2     W (warning)
            #   Error   = 3     E (error)
            #   Fatal   = 4     E (error)
            # ----------------------------------
            if severity == 0:
                return 'I'
            elif severity == 1:
                return 'I'
            elif severity == 2:
                return 'W'
            elif severity >= 3:
                return 'E'
            return '0'

        def diag_callback(filename, line, column, spelling, severity, category_number, category_name, fixits_iterator, diagnostics):
            def fixits_callback(range, value, fixit_hint):
                fixit_hint.append(
                    "Try using '" + str(value) + "' instead (col" + str(range.start.column) + " -> col" + str(range.end.column) + ")"
                )
                # TODO How to handle multiline quickfix entries? It would be nice show each fixit in its own line.

            fixit_hint = []
            diagnostics.append(
                "{'filename': '" + str(filename) + "', " +
                "'lnum': '" + str(line) + "', " +
                "'col': '" + str(column) + "', " +
                "'type': '" + clang_severity_to_quickfix_type(severity) + "', " +
                "'text': '" + category_name + " | " + spelling.replace("'", r"") + "'}"
            )
            fixit_visitor(fixits_iterator, fixits_callback, fixit_hint)
            diagnostics.append(
                "{'filename': '" + str(filename) + "', " +
                "'lnum': '" + str(line) + "', " +
                "'col': '" + str(column) + "', " +
                "'type': 'I', " +
                "'text': 'Hint: " + str(' '.join(fixit_hint)).replace("'", r"") + "'}"
            )

        vim_diagnostics = []
        if success:
            diagnostics_iterator, diagnostics_visitor, fixit_visitor = args
            diagnostics_visitor(diagnostics_iterator, diag_callback, vim_diagnostics)
        else:
            logging.error('Something went wrong in diagnostics service ... Diagnostics not available. Payload={0}'.format(payload))

        Utils.call_vim_remote_function(
            self.servername,
            "cxxd#services#source_code_model#diagnostics#run_callback(" + str(int(success)) + ", " + str(vim_diagnostics).replace('"', r"") + ")"
        )

        logging.debug("Diagnostics: " + str(vim_diagnostics))
