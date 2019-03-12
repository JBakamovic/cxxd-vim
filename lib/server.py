import cxxd.server
from services.clang_format.clang_format import VimClangFormat
from services.clang_tidy.clang_tidy import VimClangTidy
from services.project_builder.project_builder import VimProjectBuilder
from services.source_code_model.source_code_model import VimSourceCodeModel
from services.code_completion.code_completion import VimCodeCompletion

def get_instance(handle, project_root_directory, target_configuration, args):
    vim_instance = args
    return cxxd.server.Server(
        handle,
        project_root_directory,
        target_configuration,
        VimSourceCodeModel(vim_instance),
        VimProjectBuilder(vim_instance),
        VimClangFormat(vim_instance),
        VimClangTidy(vim_instance),
        VimCodeCompletion(vim_instance)
    )
