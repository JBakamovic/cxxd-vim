# Tasks

- [x] Explore repository structure and purpose <!-- id: 0 -->
    - [x] List files in root <!-- id: 1 -->
    - [x] Read README <!-- id: 2 -->
    - [x] List lib and plugin directories <!-- id: 4 -->
    - [x] Read plugin/cxxd.vim and lib/server.py <!-- id: 6 -->
    - [x] Check cxxd submodule content <!-- id: 7 -->
    - [x] List plugin/cxxd and lib/services <!-- id: 8 -->
    - [x] Read plugin/cxxd/server.vim <!-- id: 9 -->
    - [x] Analyze support code in lib <!-- id: 5 -->
    - [x] Analyze build configuration and usage of cxxd <!-- id: 3 -->

- [x] Analyze cxxd submodule <!-- id: 10 -->
    - [x] List cxxd submodule contents <!-- id: 11 -->
    - [x] Read lib/cxxd/api.py and lib/cxxd/server.py <!-- id: 12 -->
    - [x] Confirm libclang usage in parser/clang_parser.py <!-- id: 15 -->
    - [x] Understand C++ server entry point <!-- id: 13 -->

- [x] Trace `CxxdGoToDefinition` flow <!-- id: 16 -->
    - [x] Locate Vimscript implementation of `go_to_definition` <!-- id: 17 -->
    - [x] Trace from Vim to Python Bridge <!-- id: 18 -->
    - [x] Read `lib/cxxd/services/source_code_model_service.py` <!-- id: 21 -->
    - [x] Read `lib/cxxd/service.py` <!-- id: 22 -->
    - [x] Read `lib/services/source_code_model/source_code_model.py` <!-- id: 23 -->
    - [x] Read `lib/cxxd/services/source_code_model/go_to_definition/go_to_definition.py` <!-- id: 24 -->
    - [x] Read `lib/services/source_code_model/go_to_definition/go_to_definition.py` <!-- id: 25 -->
    - [x] Trace response back to Vim <!-- id: 20 -->

- [x] Investigate callback mechanism improvements <!-- id: 26 -->
    - [x] Analyze `lib/utils.py` for current `call_vim_remote_function` implementation <!-- id: 27 -->
    - [x] Check `lib/cxxd/api.py` for standalone script suitability <!-- id: 31 -->
    - [x] Create `implementation_plan.md` for Job-based architecture <!-- id: 32 -->

- [ ] Implement Job-based Architecture <!-- id: 33 -->
    - [x] Create `lib/cxxd/messenger.py` <!-- id: 34 -->
    - [x] Update `lib/services/source_code_model/go_to_definition/go_to_definition.py` to use Messenger <!-- id: 35 -->
    - [x] Create `lib/cxxd/main.py` (The Bridge) <!-- id: 36 -->
    - [x] Create `plugin/cxxd/job.vim` <!-- id: 37 -->
    - [x] Update `plugin/cxxd/server.vim` to use Job API <!-- id: 38 -->
    - [x] Update `plugin/cxxd/services/source_code_model/go_to_definition.vim` to use Job API <!-- id: 41 -->
    - [x] Check `lib/cxxd/__init__.py` existence <!-- id: 42 -->
    - [x] Add Vim 8 support to `plugin/cxxd/job.vim` <!-- id: 43 -->
    - [x] Add Vim 8 support to `plugin/cxxd/server.vim` <!-- id: 44 -->
    - [x] Update `walkthrough.md` to reflect Vim 8 support <!-- id: 46 -->
    - [x] Verification: Ready for Manual Testing (See walkthrough.md) <!-- id: 40 -->
    - [x] Verification: Ready for Manual Testing (See walkthrough.md) <!-- id: 40 -->

- [x] Commit and Push Changes <!-- id: 47 -->
    - [x] Create branch and commit in `lib/cxxd` ecosystem <!-- id: 48 -->
    - [x] Create branch and commit in main repository <!-- id: 49 -->
