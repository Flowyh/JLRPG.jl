module JLPG_Parser
  using ..JLPG: Comparable, full_function_pattern

  include("types.jl")
  export Parser, ParserOptions, ParserProduction
  export augment_parser, parser_grammar_symbols
  export ParsingItem
  export ParsingTableAction, Shift, Reduce, Accept, ParsingError
  export ParsingTable, SlrParsingTable
  export EMPTY_PRODUCTION, EMPTY_SYMBOL, END_OF_INPUT, AUGMENTED_START

  include("definition/reader.jl")
  export read_parser_definition_file

  include("first_follow.jl")
  export nullable, first_sets, follow_sets

  include("slr.jl")
  export lr0_closure, lr0_goto, lr0_items

  include("codegen/fill_template.jl")
  export fill_parser_template

  include("codegen/special_replacements.jl")
  export replace_special_variables_in_generated_parser
  export replace_overloaded_functions_in_generated_parser

  include("generate_parser.jl")
  export generate_parser
end
