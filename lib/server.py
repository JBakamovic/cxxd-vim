from __future__ import absolute_import
import cxxd.server
import services.clang_format.clang_format
import services.clang_tidy.clang_tidy
import services.project_builder.project_builder
import services.source_code_model.source_code_model
import services.code_completion.code_completion
#from . services.clang_format.clang_format import VimClangFormat
#from . services.clang_tidy.clang_tidy import VimClangTidy
#from . services.project_builder.project_builder import VimProjectBuilder
#from . services.source_code_model.source_code_model import VimSourceCodeModel
#from . services.code_completion.code_completion import VimCodeCompletion

def get_instance(handle, project_root_directory, target_configuration, args):
    vim_instance = args
    return cxxd.server.Server(
        handle,
        project_root_directory,
        target_configuration,
        services.source_code_model.source_code_model.VimSourceCodeModel(vim_instance),
        services.project_builder.project_builder.VimProjectBuilder(vim_instance),
        services.clang_format.clang_format.VimClangFormat(vim_instance),
        services.clang_tidy.clang_tidy.VimClangTidy(vim_instance),
        services.code_completion.code_completion.VimCodeCompletion(vim_instance)
    )
