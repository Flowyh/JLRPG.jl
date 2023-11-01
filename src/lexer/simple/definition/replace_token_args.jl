using Parameters: @consts

@consts begin
  CONVERSION_FUNCTION = (type, value) -> "convert_type($type, $value)"
end

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

    tag  = Symbol(m[:tag])
    args = m[:args]
    if isempty(args)
      push!(replaced_actions, action)
      continue
    end

    new_args = [
      "$name=$(CONVERSION_FUNCTION(type, value))"
      for (name, type, value) in defined_tokens[tag]
    ]
    new_return = replace(m.match, args => ";$(join(new_args, ", "))")

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
