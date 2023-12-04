module JLPG_Parser
  using ..JLPG_Utils: Comparable
  using ..JLPG_Utils: function_definition, function_name
  using ..JLPG_Utils: SPECIAL_FUNCTION_START, SPECIAL_FUNCTION_END,
                      SPECIAL_FUNCTION_OVERLOAD_MSG
  using ..JLPG_Utils.Cursors

  include("types.jl")
  export Parser, ParserOptions, ParserProduction
  export augment_parser, parser_grammar_symbols
  export ParsingItem
  export ParsingTableAction, Shift, Reduce, Accept, ParsingError
  export ParsingTable
  export EMPTY_PRODUCTION, EMPTY_SYMBOL, END_OF_INPUT, AUGMENTED_START

  include("definition/reader.jl")
  export read_parser_definition_file

  include("first_follow.jl")
  export nullable, first_sets, follow_sets
  export first_set_for_string_of_symbols

  include("slr.jl")
  export lr0_closure, lr0_goto, lr0_items
  export SlrParsingTable

  include("lr1.jl")
  export lr1_closure, lr1_goto, lr1_items
  export LrParsingTable

  include("lalr.jl")
  export lr1_kernels, merge_lr1_kernels
  export LalrParsingTable

  include("codegen/fill_template.jl")
  export fill_parser_template

  include("codegen/special_replacements.jl")
  export replace_special_variables_in_generated_parser
  export replace_overloaded_functions_in_generated_parser

  include("generate_parser.jl")
  export generate_parser
end
