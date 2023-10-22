module JLPG_SimpleLexer
  using ..JLPG: Comparable

  include("types.jl")
  export Lexer, RegexAlias, Action, Options, TokenDefinition

  include("definition/reader.jl")
  export read_definition_file

  include("definition/expand_aliases.jl")
  export expand_regex_aliases_in_lexer, expand_regex_aliases_in_actions, expand_regex_aliases_in_aliases

  include("definition/retrieve_tokens.jl")
  export retrieve_tokens_from_actions, retrieve_tokens_from_lexer

  include("show.jl")
end
