# Refactor Callback Mechanism to use Vim Jobs

The current architecture relies on `gvim --remote-send` for asynchronous callbacks from the Python server to Vim. This approach is legacy, slow (spawns new processes), requires an X server (or client-server support), and is fragile.

This plan proposes migrating to a modern **Vim 8 Job / Neovim Job** architecture, where communication happens over standard I/O (JSON messages) or Channels.

## User Review Required

> [!IMPORTANT]
> **Architecture Change**: This refactor changes how the `cxxd` server is launched and how it communicates. It moves from a "Vim-embedded Python" launch to a "Vim-managed Background Process" launch.
>
> **Requirements**:
> *   Vim 8.0+ or Neovim.
> *   Python 3 available in the system path (not just embedded in Vim).

## Proposed Changes

### 1. Python Side: Abstracting Communication

We need to decouple the services from the specific communication method (`gvim --remote-send`).

#### [NEW] `lib/cxxd/messenger.py`
Create a helper class to handle sending messages back to Vim.
*   **Legacy Mode**: Wraps `Utils.call_vim_remote_function` (Preserved for unrelated commands as requested).
*   **Job Mode**: Writes JSON objects to `sys.stdout`.

#### [MODIFY] `lib/utils.py`
*   No changes needed if we wrap the legacy logic in `Messenger`.

#### [MODIFY] `lib/services/*/*.py` (e.g., `lib/services/source_code_model/go_to_definition/go_to_definition.py`)
*   Inject `Messenger` instance into these classes instead of using `Utils` directly.
*   Update `__call__` methods to usage `messenger.send_call(...)` instead of constructing strings for `remote-expr`.

### 2. Python Side: Entry Point & Architecture

We will implement a **Standalone Server Process** that communicates via Standard I/O (Pipes) but **preserves `multiprocessing.Queue` for performance and buffering**.

#### [NEW] `lib/cxxd/main.py` (The Wrapper)
This script acts as the "Bridge". It translates external JSON requests into the internal tuple-based protocol `cxxd` expects.

**Protocol Translation Example:**
The current `cxxd` protocol uses lists/tuples like `[ServiceId, ActionId, [Args...]]`.
The new JSON protocol will look like: `{"service": 0, "action": 1, "args": [...]}`.

```python
import sys
import json
import threading
from multiprocessing import Queue
from cxxd.server import Server

def stdin_reader(server_queue):
    """
    Reads NDJSON (Newline Delimited JSON) from stdin.
    Translates JSON -> Internal Protocol -> Queues.
    """
    for line in sys.stdin:
        try:
            req = json.loads(line)
            # Translation: JSON dict -> Internal List Protocol
            # Example: {"s": 0x4, "a": 0xF2, "p": ["file.cpp", ...]} -> [0xF2, 0x4, ["file.cpp", ...]]
            # NOTE: internal protocol structure varies (ServerRequestId vs ServiceId), 
            # we will standardize on a wrapper protocol or map explicitly.
            internal_request = [
                req.get("header", 0xF2), # 0xF2 = SEND_SERVICE (default for general requests)
                req.get("service_id"),
                req.get("payload", [])
            ]
            server_queue.put(internal_request)
        except Exception as e:
            sys.stderr.write(f"Error parsing request: {e}\n")

def run():
    server_queue = Queue()
    # ... instantiate request_reader thread ...
    # ... instantiate server process with server_queue ...
```

**Q&A on Architecture Choices:**

1.  **Pipes vs Sockets (Multi-client?)**:
    *   **Pipes (Stdin/Stdout)**: Ideal for 1-to-1 relationship (One Vim instance owns One cxxd server). This simplifies lifecycle (Server dies when Vim dies).
    *   **Sockets**: Indeed allow multi-client (e.g., multiple Vim instances sharing one `cxxd` for the same project). *However*, this introduces complexity: concurrency management, shared state bugs, and manual port discovery.
    *   **Decision**: For this refactor, we strictly replicate existing 1-to-1 behavior using Pipes for robustness.

2.  **Large Payloads (FindAllReferences)**:
    *   **Limit**: OS pipes have buffers (often 64KB), but blocking occurs only if the reader (Vim) stops reading.
    *   **Solution**: We use **NDJSON (Newline Delimited JSON)**. Each message is one line.
    *   **Vim Side**: Vim's `channel` and `job` API handles buffering efficiently. It reads raw bytes and fires the callback when a full newline-terminated JSON object is complete.
    *   **Restriction**: We must ensure no newline characters exist *inside* the JSON string representation (standard `json.dumps` escapes newlines as `\n` by default, so this is safe).

### 3. Vim Side: Job Management

### 3. Vim Side: Job Management

#### [MODIFY] `plugin/cxxd/server.vim`
*   Detect `job_start` (Vim 8) or `jobstart` (Neovim) capability.
*   **Start**: Instead of `python3 cxxd.api.server_start`, build a command list `['python3', '/path/to/lib/cxxd/main.py', ...]`.
*   **Launch**: call `job_start(cmd, {'out_cb': 'CxxdJobHandler', 'mode': 'json'})`.
*   **Stop**: `job_stop(job_id)`.

#### [NEW] `plugin/cxxd/job.vim`
*   Implement `CxxdJobHandler(channel, msg)` to parse JSON messages and execute callbacks.
*   The message format should look like: `{"function": "cxxd#func", "args": [...]}`.

## Verification Plan

### Automated Tests
*   Since the repo lacks a comprehensive test suite, we will verify manually first.
*   We can create a small test script that mocks the Vim side (writes to stdin, reads stdout) to verify protocols.

### Manual Verification
1.  **Launch**: Start Vim in a C++ project. Verify server starts (check logs).
2.  **Feature Test**: `CxxdGoToDefinition`.
    *   Trigger command.
    *   Verify the request is sent via stdin (by checking server logs or `strace`).
    *   Verify the response comes back via stdout and Vim executes the jump.
3.  **Stress Test**: Rapidly trigger commands to ensure no "broken pipe" or interleaved JSON issues.
