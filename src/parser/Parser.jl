module JLPG_Parser
  using ..JLPG: Comparable

  include("types.jl")
  export Parser, ParserOptions, ParserProduction
  export augment_parser, parser_grammar_symbols
  export ParsingItem
  export ParsingTableAction, Shift, Reduce, Accept, Error
  export ParsingTable, SlrParsingTable
  export EMPTY_PRODUCTION, EMPTY_SYMBOL, END_OF_INPUT, AUGMENTED_START

  include("definition/reader.jl")
  export read_parser_definition_file

  include("first_follow.jl")
  export nullable, first_sets, follow_sets

  include("slr.jl")
  export lr0_closure, lr0_goto, lr0_items
end
