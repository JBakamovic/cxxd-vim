from builtins import str
from builtins import object
import logging
import time
from utils import Utils
from cxxd.parser.ast_node_identifier import ASTNodeId
from cxxd.parser.ctags_parser import CtagsTokenizer

class VimSemanticSyntaxHighlight(object):
    def __init__(self, servername, output_syntax_file):
        self.servername = servername
        self.output_syntax_file = output_syntax_file

    def __call__(self, success, payload, args):
        class VimHlMatch(object):
            def __init__(self, group, line, column, length):
                self.group = group
                self.line = line
                self.column = column
                self.length = length

            def __hash__(self):
                return hash((self.group, self.line, self.column, self.length))

            def __eq__(self, other):
                if self.group == other.group and self.line == other.line and self.column == other.column and self.length == other.length:
                    return True
                return False

        def create_clearmatches_pattern():
            return "call clearmatches()"

        def create_matchaddpos_pattern(hl_match):
            return "call matchaddpos('" + hl_match.group + "', [[" + str(hl_match.line) + ", " + str(hl_match.column) + ", " + str(hl_match.length) + "]])"

        def callback(ast_node_id, ast_node_name, ast_node_line, ast_node_column, syntax):
            syntax.add(
                VimHlMatch(
                    VimSemanticSyntaxHighlight.__tag_id_to_vim_syntax_group(ast_node_id),
                    ast_node_line,
                    ast_node_column,
                    len(ast_node_name)
                )
            )

        def call_vim_rpc(status, filename, syntax_file):
            Utils.call_vim_remote_function(
                self.servername,
                "cxxd#services#source_code_model#semantic_syntax_highlight#run_callback(" + str(int(status)) + ", '" + filename + "'" + ", '" + syntax_file + "')"
            )

        if success:
            # Unpack the parameters
            tunit, line_begin, line_end, traverse = args

            # Build Vim syntax highlight rules
            vim_syntax_hl_patterns = set()
            traverse(tunit, line_begin, line_end, callback, vim_syntax_hl_patterns)

            # Write Vim syntax file
            with open(self.output_syntax_file, "w") as vim_syntax_file:
                vim_syntax_file.write(create_clearmatches_pattern() + '\n')                 # TODO 'vim_syntax_hl_patterns' is an unordered set and therefore resulting
                for hl_pattern in vim_syntax_hl_patterns:                                   #       vim syntax file will contain 'matchaddpos' entries which are not
                    vim_syntax_file.write(create_matchaddpos_pattern(hl_pattern) + '\n')    #       going to be ordered by [line, column]. It needs to be checked if

            # Apply newly generated syntax rules
            call_vim_rpc(success, payload[1], self.output_syntax_file)
        else:
            call_vim_rpc(success, '', '')
            logging.error('Something went wrong in semantic syntax highlighting service ... Payload={0} Args={1}'.format(payload, args))

    def generate_vim_syntax_file_from_ctags(self, filename):
        # Generate the tags
        output_tag_file = "/tmp/syntax_file.vim"
        tokenizer = CtagsTokenizer(output_tag_file)
        tokenizer.run(filename)

        # Generate the vim syntax file
        tags_db = None
        try:
            with open(output_tag_file) as tags_db:
                # Build Vim syntax highlight rules
                vim_highlight_rules = set()
                for line in tags_db:
                    if not tokenizer.is_header(line):
                        highlight_rule = VimSemanticSyntaxHighlight.__tag_id_to_vim_syntax_group(tokenizer.get_token_id(line)) + " " + tokenizer.get_token_name(line)
                        vim_highlight_rules.add(highlight_rule)

            vim_syntax_hl_patterns = []
            for rule in vim_highlight_rules:
                vim_syntax_hl_patterns.append("syntax keyword " + rule + "\n")

            # Write syntax file
            with open(self.output_syntax_file, "w") as vim_syntax_file:
                vim_syntax_file.writelines(vim_syntax_hl_patterns)
        finally:
            if tags_db is not None:
                tags_db.close()

    @staticmethod
    def __tag_id_to_vim_syntax_group(tag_identifier):
        if tag_identifier == ASTNodeId.getNamespaceId():
            return "CxxdNamespace"
        if tag_identifier == ASTNodeId.getNamespaceAliasId():
            return "CxxdNamespaceAlias"
        if tag_identifier == ASTNodeId.getClassId():
            return "CxxdClass"
        if tag_identifier == ASTNodeId.getStructId():
            return "CxxdStructure"
        if tag_identifier == ASTNodeId.getEnumId():
            return "CxxdEnum"
        if tag_identifier == ASTNodeId.getEnumValueId():
            return "CxxdEnumValue"
        if tag_identifier == ASTNodeId.getUnionId():
            return "CxxdUnion"
        if tag_identifier == ASTNodeId.getFieldId():
            return "CxxdField"
        if tag_identifier == ASTNodeId.getLocalVariableId():
            return "CxxdLocalVariable"
        if tag_identifier == ASTNodeId.getFunctionId():
            return "CxxdFunction"
        if tag_identifier == ASTNodeId.getMethodId():
            return "CxxdMethod"
        if tag_identifier == ASTNodeId.getFunctionParameterId():
            return "CxxdFunctionParameter"
        if tag_identifier == ASTNodeId.getTemplateTypeParameterId():
            return "CxxdTemplateTypeParameter"
        if tag_identifier == ASTNodeId.getTemplateNonTypeParameterId():
            return "CxxdTemplateNonTypeParameter"
        if tag_identifier == ASTNodeId.getTemplateTemplateParameterId():
            return "CxxdTemplateTemplateParameter"
        if tag_identifier == ASTNodeId.getMacroDefinitionId():
            return "CxxdMacroDefinition"
        if tag_identifier == ASTNodeId.getMacroInstantiationId():
            return "CxxdMacroInstantiation"
        if tag_identifier == ASTNodeId.getTypedefId():
            return "CxxdTypedef"
        if tag_identifier == ASTNodeId.getUsingDirectiveId():
            return "CxxdUsingDirective"
        if tag_identifier == ASTNodeId.getUsingDeclarationId():
            return "CxxdUsingDeclaration"

def main():
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("filename",                                                       help="source code file to generate the source code highlighting for")
    parser.add_argument("output_syntax_file",                                             help="resulting Vim syntax file")
    args = parser.parse_args()
    args_dict = vars(args)

    vimHighlighter = VimSemanticSyntaxHighlight(args.output_syntax_file)
    vimHighlighter(args.filename, [''])

if __name__ == "__main__":
    main()

