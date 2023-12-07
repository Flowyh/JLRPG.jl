using Parameters: @consts

"""
    replace_token_args_in_actions(
      lexer::Lexer,
      defined_tokens::Vector{LexerTokenDefinition}
    )::Lexer

Convert token definitions from lexer definition file to conform to the code
generation template.

This function does two things:
  - Prepends a special lexer tag to each token name. This is done to avoid name
    collisions with user-defined functions.
  - Replaces arguments passed to returned tokens with a list of keyword arguments.
    Argument names should be defined in the `defined_tokens` vector.

For example `return Number(1)` will become `return __LEX__Number(;value=1)`.
"""
function replace_token_args_in_actions(
  actions::Vector{LexerAction},
  defined_tokens::Dict{Symbol, Vector}
)::Vector{LexerAction}
  replaced_actions::Vector{LexerAction} = []

  for action in actions
    pattern, body = action.pattern, action.body
    m = match(RETURNED_TOKEN_PATTERN, body)
    if m === nothing
      push!(replaced_actions, action)
      continue
    end

    tag_str = m[:tag]
    tag = Symbol(tag_str)

    new_tag = LEXER_SPECIAL_TAG.pattern * tag_str
    new_return = replace(m.match, tag_str => new_tag)

    args = m[:args]
    if !isempty(args)
      new_args = [
        "$name=$value"
        for (name, _, value) in defined_tokens[tag]
      ]
      new_return = replace(new_return, args => ";$(join(new_args, ", "))")
    end

    push!(replaced_actions, LexerAction(
      pattern,
      replace(body, m.match => new_return)
    ))
  end

  return replaced_actions
end

function replace_token_args_in_lexer(
  lexer::Lexer,
  defined_tokens::Vector{LexerTokenDefinition}
)::Lexer
  defined_tokens_args = Dict{Symbol, Vector}(
    token.name => token.arguments for token in defined_tokens
  )
  replaced_actions = replace_token_args_in_actions(lexer.actions, defined_tokens_args)
  return Lexer(
    replaced_actions,
    lexer.aliases,
    lexer.code_blocks,
    lexer.options
  )
end

#============#
# PRECOMPILE #
#============#
precompile(replace_token_args_in_lexer, (
  Lexer,
  Vector{LexerTokenDefinition}
))
precompile(replace_token_args_in_actions, (
  Vector{LexerAction},
  Dict{Symbol, Vector}
))
