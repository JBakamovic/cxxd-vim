#!/bin/python3

import argparse

cxxd_vim_specific_highlight_links = """
hi! link NamespaceTag                 Identifier
hi! link NamespaceAliasTag            Identifier
hi! link ClassTag                     Type
hi! link StructureTag                 Type
hi! link UnionTag                     Type
hi! link EnumTag                      Type
hi! link EnumValueTag                 Constant
hi! link FieldTag                     Identifier
hi! link LocalVariableTag             Identifier
hi! link FunctionParameterTag         Identifier
hi! link MethodTag                    Function
hi! link FunctionTag                  Function
hi! link TemplateTypeParameterTag     Type
hi! link TemplateNonTypeParameterTag  Type
hi! link TemplateTemplateParameterTag Type
hi! link MacroDefinitionTag           PreProc
hi! link MacroInstantiationTag        PreProc
hi! link TypedefTag                   Type
hi! link UsingDirectiveTag            Identifier
hi! link UsingDeclarationTag          Type
"""

def main():
    parser = argparse.ArgumentParser(formatter_class=argparse.RawDescriptionHelpFormatter, \
            description='cxxd has a semantic understanding of the C and C++ code. Because of that\n'
            'it can generate Vim colorscheme tags/groups at much more finer level than what\n'
            'vanilla Vim colorscheme will support. This is called semantic syntax highlighting.\n'
            '\n'
            'This tool is envisioned to help convert your favorite Vim colorscheme into a format\n'
            'so that cxxd-vim can take advantage of semantic syntax highlighting support built into\n'
            'a cxxd.\n'
            '\n'
            'What will it basically do is that it will link special syntax highlighting groups generated\n'
            'by the cxxd to the groups defined by Vim as "preferred" so it shouldn\'t be destructive by any\n'
            'means.\n'
            '\n'
            'Preferred groups are only handful and source-code wise those include only [Identifier, \n'
            'Statement, PreProc, Constant, Type]. This is why conversion is rather conservative\n'
            'and it may or may not end up with the best results. It mostly depends on how well and detailed \n'
            'the given colorscheme is implemented and/or tweaked towards the C and C++ syntax.\n'
            '\n'
            'New highlighting groups that will be linked against the "preferred" ones are:\n'
            '{}'.format(cxxd_vim_specific_highlight_links))
    parser.add_argument('colorscheme', nargs='+', help='Existing Vim colorscheme to be converted into a semantic syntax highlighting format.')
    args = parser.parse_args()

    for c in args.colorscheme:
        with open(c, 'r') as f:
            buf = f.readlines()
        with open(c, 'w') as f:
            for line in buf:
                if line == "hi clear\n":
                    line = line + cxxd_vim_specific_highlight_links + '\n'
                f.write(line)

if __name__ == "__main__":
    main()
