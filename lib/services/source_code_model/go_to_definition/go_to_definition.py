import logging
from cxxd.messenger import Messenger

class VimGoToDefinition:
    def __init__(self, servername):
        self.servername = servername
        # Determine mode based on servername (if None/empty, assume Job mode)
        # Note: Ideally this is passed in, but for backward compat we infer:
        # If servername is passed, we might be in Legacy mode.
        # But wait, the new main.py will likely NOT pass a servername (or pass a special flag).
        # For now, let's assume we can detect mode.
        # FIX: The current architecture constructs VimGoToDefinition with `servername`.
        # In Job mode, servername might be None or unused.
        self.mode = Messenger.MODE_LEGACY if servername else Messenger.MODE_JOB
        self.messenger = Messenger(self.mode, servername)

    def __call__(self, success, payload, definition):
        if success:
            filename, line, column = definition
            # Call back to Vim
            self.messenger.send_call(
                "cxxd#services#source_code_model#go_to_definition#run_callback",
                int(success), filename, line, column
            )
            logging.info('Definition found at {0} [{1}, {2}]'.format(filename, line, column))
        else:
            self.messenger.send_call(
                "cxxd#services#source_code_model#go_to_definition#run_callback",
                int(success), '', 0, 0
            )
            logging.error('Something went wrong in go-to-definition service ... Definition not found. Payload = {0}'.format(payload))
