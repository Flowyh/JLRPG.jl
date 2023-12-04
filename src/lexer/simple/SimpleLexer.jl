module JLPG_SimpleLexer
  using ..JLPG_Utils: Comparable
  using ..JLPG_Utils: function_definition, function_name
  using ..JLPG_Utils: SPECIAL_FUNCTION_START, SPECIAL_FUNCTION_END,
                      SPECIAL_FUNCTION_OVERLOAD_MSG
  using ..JLPG_Utils.Cursors

  include("types.jl")
  export Lexer, RegexAlias, LexerAction, LexerOptions, LexerToken, LexerTokenDefinition
  export token_symbol, token_values, token_file_pos

  include("definition/reader.jl")
  export read_lexer_definition_file

  include("definition/expand_aliases.jl")
  export expand_regex_aliases_in_lexer
  export expand_regex_aliases_in_actions
  export expand_regex_aliases_in_aliases

  include("definition/retrieve_tokens.jl")
  export retrieve_tokens_from_actions, retrieve_tokens_from_lexer

  include("definition/replace_token_args.jl")
  export replace_token_args_in_actions, replace_token_args_in_lexer

  include("codegen/fill_template.jl")
  export fill_lexer_template

  include("codegen/special_replacements.jl")
  export replace_special_variables_in_generated_lexer
  export replace_overloaded_functions_in_generated_lexer
  export replace_special_tag_in_generated_lexer
  export LEXER_SPECIAL_TAG

  include("generate_lexer.jl")
  export generate_lexer

  include("show.jl")
  export show_simple
end
