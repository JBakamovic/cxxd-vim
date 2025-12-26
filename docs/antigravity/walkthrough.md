# Job-Based Architecture Migration

I have successfully refactored `cxxd-vim` to use modern Vim 8 / Neovim Jobs instead of the legacy `clientserver` (`--remote-send`) mechanism.

## Changes Implemented

### 1. Standalone Server Bridge (`lib/cxxd/main.py`)
*   **New Entry Point**: Created a standalone python script that runs the `cxxd` server.
*   **Protocol Translation**: reads **NDJSON** (Newline Delimited JSON) from `stdin` and translates it to the internal `cxxd` protocol (`[Header, ServiceId, Payload]`).
*   **Performance**: Preserves the `multiprocessing.Queue` architecture for high-performance buffering.

### 2. Communication Abstraction (`lib/cxxd/messenger.py`)
*   **Messenger Class**: Decouples services from `gvim --remote-send`.
*   **Modes**: Supports both `LEGACY` (for unchanged services) and `JOB` (writing JSON to `stdout`).

### 3. Vim Integration (`plugin/cxxd/`)
*   **`server.vim`**: Updated to support both `jobstart()` (Neovim) and `job_start()` (Vim 8) to launch `lib/cxxd/main.py`.
*   **`job.vim`**: Handles callbacks from both Neovim (list-based) and Vim 8 (channel/line-based).
*   **`go_to_definition.vim`**: Updated to send JSON requests.

### 4. Service Update (`GoToDefinition`)
*   Updated `lib/services/source_code_model/go_to_definition/go_to_definition.py` to use `Messenger` for sending results back to Vim.

## Verification Steps (Manual)

1.  **Start Vim / Neovim**:
    *   Works with **Neovim** (v0.2+) or **Vim 8.0+** (with `+job` and `+channel`).
2.  **Open C++ Project**: Open a `.cpp` file in a project compatible with `cxxd`.
3.  **Start Server**: `:CxxdStart` (or auto-start if configured).
    *   **Check**: Verify `_cxxd_server.log` (path printed in messages) is created and shows startup info.
    *   **Check**: Run `:jobs` (Vim 8) or check process list.
4.  **Test GoToDefinition**:
    *   Place cursor on a symbol.
    *   Execute `:CxxdGoToDefinition` (or `<F12>`).
    *   **Success**: Vim should jump to the definition file/line.
    *   **Logs**: Check log file for "Stdin reader thread started", "Definition found at ...", etc.

## Notes & Limitations
*   **Partial Migration**: Only `GoToDefinition` is fully migrated. Other services (ClangTidy, CodeCompletion, etc.) might break or behave unexpectedly if they rely on the old `server_handle` in embedded python, which is no longer initialized in the main Vim process.
    *   *Follow-up*: Fully migrate other services using the patterns established here.
