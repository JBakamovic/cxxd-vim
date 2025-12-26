import cxxd.server
import services.clang_format.clang_format
import services.clang_tidy.clang_tidy
import services.project_builder.project_builder
import services.source_code_model.source_code_model
import services.code_completion.code_completion
import services.disassembly.disassembly

def get_instance(handle, project_root_directory, target_configuration, args):
    return cxxd.server.Server(
        handle,
        project_root_directory,
        target_configuration,
        services.source_code_model.source_code_model.VimSourceCodeModel(args),
        services.project_builder.project_builder.VimProjectBuilder(args),
        services.clang_format.clang_format.VimClangFormat(args),
        services.clang_tidy.clang_tidy.VimClangTidy(args),
        services.code_completion.code_completion.VimCodeCompletion(args),
        services.disassembly.disassembly.VimDisassembly(args)
    )
