# Contents
* [Introduction](#introduction)
* [Installation](#installation)
  * [Dependencies](#dependencies)
  * [Plugin managers](#plugin-managers)
  * [Manual](#manual)
* [Features](#features)
* [Supported platforms](#supported-platforms)
* [Configuration](#configuration)
  * [JSON Compilation Database](#json-compilation-database)
  * [Plain txt file](#plain-txt-file)
* [Colorschemes](#colorschemes)
* [Usage](#usage)
* [Screenshots](#screenshots)
* [FAQ](#faq)

# Introduction

This is a Vim frontend for [cxxd](https://github.com/JBakamovic/cxxd) server.

# Installation

Any of your preferred way of installing Vim plugins should be fine. Please note the necessity for recursive clone. For example:

## Dependencies
[Here](https://github.com/JBakamovic/cxxd#dependencies).

## Plugin managers

### Pathogen
* `$ git clone --recursive https://github.com/JBakamovic/cxxd-vim.git ~/.vim/bundle/cxxd-vim`
* `$ git clone https://github.com/JBakamovic/yaflandia.git ~/.vim/bundle/yaflandia` (accompanying colorscheme)

### Vundle
After cloning the repository with:
* `$ git clone --recursive https://github.com/JBakamovic/cxxd-vim.git`
* `$ git clone https://github.com/JBakamovic/yaflandia.git` (accompanying colorscheme)

Add the following to your `.vimrc`
* `Plugin 'JBakamovic/cxxd-vim'`
* `Plugin 'JBakamovic/yaflandia'` (accompanying colorscheme)

## Manual

If you're not using any of the plugin managers, you can simply clone the repository into your `~/.vim/` directory:
* `$ git clone --recursive https://github.com/JBakamovic/cxxd-vim.git ~/.vim/cxxd-vim`
* `$ git clone https://github.com/JBakamovic/yaflandia.git ~/.vim/yaflandia` (accompanying colorscheme)

# Features

[Here](https://github.com/JBakamovic/cxxd/blob/master/README.md#features)

# Supported platforms

[Here](https://github.com/JBakamovic/cxxd/blob/master/README.md#supported-platforms)

# Configuration
For the best experience, your project root directory shall expose a configuration file which contains compiler flags being used for the build. It can be done with either of the following methods:
* [JSON Compilation Database](#json-compilation-database) **or**
* a simple [plain txt file](#plain-txt-file)

## Where do you put a configuration file?

Be it JSON compilation database or simple plain txt file `cxxd-vim` will try its best to auto-detect the location of
file by searching through commonly expected build locations such as:
* `.` (root directory where the source code is),
* `build`,
* `build_cmake`,
* `cmake_build`,
* `../build`,
* `../build_cmake`,
* `../cmake_build`

These search paths are **configurable** via [`g:cxxd_compilation_db_discovery_dir_paths`](https://github.com/JBakamovic/cxxd-vim/blob/master/plugin/cxxd.vim#L65-L73) variable,
and therefore can be extended with more specific search paths if needed. E.g. when your project uses different paths than the ones provided by default.

## JSON Compilation Database

### `CMake`/`ninja` projects

Run `cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON <path_to_your_source_root_dir>`.

To automate this step and make sure that compilation database is always up-to-date, one can integrate it into the `CMakeLists.txt` by `set(CMAKE_EXPORT_COMPILE_COMMANDS ON)`.

### Non-`CMake`/`ninja` projects

Consult the documentation of your build system and have a look if it supports the generation of JSON compilation databases. If it doesn't then:
* Use [Bear](https://github.com/rizsotto/Bear) or
* Fallback to creating a [plain txt file](#plain-txt-file) yourself.

## Plain txt file

This file **must** be named `compile_flags.txt` and shall contain one compiler flag per each line. E.g.
```
-I./lib
-I./include
-DFEATURE_XX
-DFEATURE_YY
-Wall
-Werror
```

# Colorschemes

Compared to the vanilla `Vim` syntax highlighting mechanism, `cxxd` brings _semantic_ syntax highlighting which not only that it attributes to the visual appeal but it also provides an immediate feedback on the correctness of your code (by not coloring the code in case of errors). In order to take advantage of that feature one has to use a colorscheme that knows how to make use of [additional higlighting groups](syntax/cpp/cxxd.vim).

Vanilla `Vim` colorschemes do not handle these groups by default so one will have to either tweak those existing colorschemes to include those groups or simply use [`yaflandia`](https://github.com/JBakamovic/yaflandia) for the start.

# Usage
Command | Default Key-Mapping | Purpose
------- | :-------------------: | --------
`CxxdStart <path_to_your_project_dir>` | None | Starts `cxxd` server for given project directory. Builds symbol index database. Most other commands will not have effect until symbol index database is built (which may take some time  depending on the project size).
`CxxdStop` | None | Stops `cxxd` server.
`CxxdRebuildIndex` | `<Ctrl-\>r` | Rebuilds the symbol index database.
`CxxdGoToInclude` | `<F3>` and `<Shift-F3>` | Jumps to the file included via `#include` directive.
`CxxdGoToDefintion` | `<F12>` and `<Shift-F12>` | Jumps to the symbol definition under the cursor.
`CxxdFindAllReferences` | `<Ctrl-\>s` | Finds all references of symbol under the cursor. Results are stored into a `QuickFix` list once the operation is completed.
`CxxdFetchAllDiagnostics` | `<Ctrl-\>d` | Fetches all diagnostics of all source files indexed. Results are stored into a `QuickFix` list once the operation is completed.
`CxxdAnalyzerClangTidyBuf` | `<F5>` | Runs `clang-tidy` on current file. Results are stored into a `QuickFix` list once `clang-tidy` is completed.
`CxxdAnalyzerClangTidyApplyFixesBuf` | `<Shift-F5>` | Runs `clang-tidy` on current file and applies the fixes. Results are stored into a `QuickFix` list once `clang-tidy` is completed.
`CxxdBuildRun <build_cmd>` | None | Runs a build with `<build_cmd>` provided. `<build_cmd>` can be of any arbitrary form which fits the build system your project is using (e.g. `make`, `make clean`, `make debug`, `make test`, etc.). Results are stored into a `QuickFix` list once the `<build_cmd>` is completed.
`lopen` | None | Opens location list containing `clang-fix-it` hints for current buffer.
`w` | None | Re-formats the source code in current buffer with `clang-format`.
`mouse hover over the symbol` | None | Shows a symbol type in a small balloon.
`colorscheme yaflandia` | None | Activates a colorscheme which has support for semantic syntax highlighting. Any other compatible colorscheme can be used of course.

# Screenshots
## Semantic syntax highlighting

![Semantic syntax hl](https://raw.githubusercontent.com/wiki/JBakamovic/cxxd-vim/images/semantic-syntax-hl.png)

## Go-to-definition

![Go to definition](https://raw.githubusercontent.com/wiki/JBakamovic/cxxd-vim/images/go-to-definition.gif)

## Go-to-include

![Go to include](https://raw.githubusercontent.com/wiki/JBakamovic/cxxd-vim/images/go-to-include.gif)

## Find-all-references

![Find all references](https://raw.githubusercontent.com/wiki/JBakamovic/cxxd-vim/images/find-all-references.gif)

## Fetch-all-diagnostics

TBD

## Type-deduction

![Type deduction](https://raw.githubusercontent.com/wiki/JBakamovic/cxxd-vim/images/type-deduction.gif)

## Clang-fix-it hints

![Clang-fix-it hints](https://raw.githubusercontent.com/wiki/JBakamovic/cxxd-vim/images/hints-fixits.gif)

## Clang-format

![Clang-format](https://raw.githubusercontent.com/wiki/JBakamovic/cxxd-vim/images/clang-format.gif)

## Clang-tidy

![Clang-tidy](https://raw.githubusercontent.com/wiki/JBakamovic/cxxd-vim/images/clang-tidy.gif)

## Project build

![Project build](https://raw.githubusercontent.com/wiki/JBakamovic/cxxd-vim/images/project-build.gif)

# FAQ

## I can't seem to see the effect of semantic syntax highlighting?

Make sure you're using a compatible colorscheme (e.g. [yaflandia](https://github.com/JBakamovic/yaflandia)).

## Not getting the behavior you expected?

Due to incorrect configuration, or lack of it, source code indexer might have stumbled upon the problems. Please use `CxxdFetchAllDiagnostics` command to debug the issues.
