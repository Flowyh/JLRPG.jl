module JLPG_SimpleLexer
  using ..JLPG: from_current_path

  include("types.jl")
  export Lexer, RegexAlias, Action, Options

  include("definition/reader.jl")
  export read_definition_file

  include("definition/expand_aliases.jl")
  export expand_regex_aliases_in_lexer, expand_regex_aliases_in_actions, expand_regex_aliases_in_aliases
end
