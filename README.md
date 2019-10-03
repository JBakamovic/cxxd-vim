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
* [Extra configuration](#extra-configuration)
  * [An example configuration](#an-example-configuration)
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
Your project **must** provide either of the following:
* [JSON Compilation Database](#json-compilation-database) **or**
* a simple [plain txt file](#plain-txt-file)

In case it doesn't, `cxxd` server will not have enough details to provide quality service and therefore it will bail-out during the startup.

## What directory do you put these files in?

If you don't provide any [extra configuration](#extra-configuration), `cxxd` will try to auto-magically detect the location of either of those files during its startup. This is only a convenience and ok to get you going but recommended method for non-trivial projects is to explicitly provide this setting through this extra configuration file (`.cxxd_config.json`).

For example, many projects will have different build-targets (`Debug` vs. `Release` vs. etc.) and that automatically implies that there will be multiple JSON compilation databases, each for one build target. In order for `cxxd` be able to process that information, we need to express this through `.cxxd_config.json`. See [extra configuration](#extra-configuration) section on more details.

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

# Extra configuration

It is possible to provide an extra (**optional**) configuration via `.cxxd_config.json` file which can be used to provide project-specific settings for things such as:
1. Defining arbitrary number of build-configurations you want to run `cxxd` with.
  * I.e. `Debug` vs. `Release` vs `RelWithDbgInfo` vs. `WhateverYouHaveInYourProject`
  * This is important if you want `cxxd` server to understand the differences between different build-configurations.
    * E.g. This setting will basically impact the whole underlying source-code-model `cxxd` is using, which means that everything from indexing to code-completion and symbol-resolution is going to be (rightly) affected.
  * Much much more details can be found at [this commit](https://github.com/JBakamovic/cxxd/commit/06d2743cb11fb4c89e69314f60b7e599e2040aef).
  * For a quickstart how to make use of this feature have a look at the `configuration` section in the underlying example configuration.
2. Skipping certain directories during the indexer operation.
  * I.e. this is handy if you don't want to index directories from build-system artifacts, external dependencies and alike.
    * This will generally result in better performance of indexer.
3. Defining non-standard C and C++ file extensions your project might be using (e.g. '.tcc', '.txx', '.whatever').
  * This is important if you want to get precise indexer operations (e.g. `find-all-references`) because it instructs
    the indexer to index those files as well.
4. Configuring clang-tidy by providing *whatever* arguments it supports.
5. Configuring clang-format by providing *whatever* arguments it supports.
6. Configuring build-system you use by providing *whatever* arguments it supports.
7. Selecting specific clang-tidy executable.
 * Useful if you don't want to use system-wide available clang-tidy executable (default).
8. Selecting specific clang-format executable.
 * Useful if you don't want to use system-wide available clang-format executable (default).

File is expected to exist at the root of the project directory. How to write one see next section.

## An example configuration

This is how it *may* look like but it all depends on your personal and project preferences.

```
{
    "configuration" : {
        "type" : "compilation-database",
        "compilation-database" : {
            "target" : {
                "debug" : "../debug_build",
                "release" : "../release_build",
                "relwithdbginfo" : "../relwithdbginfo_build"
            }
        }
    },
    "indexer" : {
        "exclude-dirs" : [
            "cmake",
            "CMakeFiles",
            "external"
        ],
        "extra-file-extensions" : [
            ".tcc",
            ".txx"
        ]
    },
    "clang-tidy" : {
        "binary" : "/opt/clang+llvm-5.0.1-x86_64-linux-gnu/bin/clang-tidy",
        "args" : {
            "-analyze-temporary-dtors" : true,
            "-explain-config" : false,
            "-format-style" : "llvm"
        }
    },
    "clang-format" : {
        "binary" : "/opt/clang+llvm-5.0.1-x86_64-linux-gnu/bin/clang-format",
        "args" : {
            "-sort-includes" : true,
            "-verbose" : true,
            "-style" : "llvm"
        }
    },
    "project-builder" : {
        "args" : {
            "--verbose" : true
        }
    }
}
```

# Colorschemes

Compared to the vanilla `Vim` syntax highlighting mechanism, `cxxd` brings _semantic_ syntax highlighting which not only that it attributes to the visual appeal but it also provides an immediate feedback on the correctness of your code (by not coloring the code in case of errors). In order to take advantage of that feature one has to use a colorscheme that knows how to make use of [additional higlighting groups](syntax/cpp/cxxd.vim).

Vanilla `Vim` colorschemes do not handle these groups by default so one will have to either tweak those existing colorschemes to include those groups or simply use [`yaflandia`](https://github.com/JBakamovic/yaflandia) for the start.

# Usage
Command | Default Key-Mapping | Purpose
------- | :-------------------: | --------
`CxxdStart <path-to-your-project-dir>` | None | Starts `cxxd` server for given project directory in auto-discovery mode. Builds symbol index database. Most other commands will not have effect until symbol index database is built (which may take some time  depending on the project size).
`CxxdStart <path-to-your-project-dir> <build-target-name>` | None | Starts `cxxd` server for given project directory and given build-target. Build-target must exist in `.cxxd_config.json` file. Builds symbol index database. Most other commands will not have effect until symbol index database is built (which may take some time  depending on the project size).
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
