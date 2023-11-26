using Parameters: @consts

@enum ArgumentType typed_named untyped_named typed_unnamed untyped_unnamed

@consts begin
  RETURNED_TOKEN_PATTERN = r"return (?<tag>\w+)\((?<args>.*)\)"
  # TODO: Fix this regex, because it's ugly and fragile

  TYPE_NAMED_TOKEN_ARGUMENT_PATTERN =
    r"(?<argname>.+?)::(?<type>\w+?)(?:\s*=\s*)(?<value>.+)"
  TYPED_UNNAMED_TOKEN_ARGUMENT_PATTERN =
    r"::(?<type>\w+?)(?:\s*=\s*)(?<value>.+)"
  UNTYPED_NAMED_TOKEN_ARGUMENT_PATTERN =
    r"(?<argname>.+?)(?:\s*=\s*)(?<value>.+)"
  UNTYPED_UNNAMED_TOKEN_ARGUMENT_PATTERN =
    r"(?<value>.+)"

  TOKEN_ARGUMENT_PATTERNS::Vector{Pair{ArgumentType, Regex}} = [
    typed_named => TYPE_NAMED_TOKEN_ARGUMENT_PATTERN,
    typed_unnamed => TYPED_UNNAMED_TOKEN_ARGUMENT_PATTERN,
    untyped_named => UNTYPED_NAMED_TOKEN_ARGUMENT_PATTERN,
    untyped_unnamed => UNTYPED_UNNAMED_TOKEN_ARGUMENT_PATTERN
  ]
end

# Each action should return some sort of token
# Tokens may contain additional values (ints, strings, symbols etc.)
# For the sake of simplicity, I will allow some sort of argument typing in returned tokens. If no type is specified, the value will be a string.
# Examples:
# {NUM} { return Num(5) } -> Num has value of type Int, but it is not specified, so we will use a string instead
# {NUM} { return Num(::Int=5) } -> Num has value of type Int
# {ID}  { return ID("hello", "world", ::Int=4)} -> ID has 3 arguments, all of which will be retrieveable by using token.value1, token.value2, token.value3
# You can also name your arguments:
# {ID}  { return ID(first::String="hello", second::String="world", num::Int=4)} -> ID has 3 arguments, all of which will be retrieveable by using token.first, token.second, token.num
# By default, if a token has only one argument, it will be named "value"
function retrieve_tokens_from_actions(actions::Vector{LexerAction})::Vector{LexerTokenDefinition}
  defined_tokens::Dict{Symbol, Vector} = Dict()
  returned_tokens::Vector{LexerTokenDefinition} = []

  for action in actions
    body = action.body
    m = match(RETURNED_TOKEN_PATTERN, body)
    if m === nothing
      continue
    end

    tag = Symbol(m[:tag])
    arguments = strip.(split(m[:args], ","))
    no_arguments = length(arguments)

    token_args::Vector{NamedTuple} = []
    for (i, argument) in enumerate(arguments)
      for (matched_type, pattern) in TOKEN_ARGUMENT_PATTERNS
        m = match(pattern, argument)
        if m === nothing
          continue
        end
        type::Symbol = :String
        argname = Symbol("value$(no_arguments == 1 ? "" : i)")
        if matched_type == typed_named
          argname = Symbol(m[:argname])
          type = Symbol(m[:type])
        elseif matched_type == untyped_named
          argname = Symbol(m[:argname])
        elseif matched_type == typed_unnamed
          type = Symbol(m[:type])
        end
        value = m[:value]
        push!(token_args, (name=argname, type=type, value=value))
        break
      end
    end

    if !haskey(defined_tokens, tag)
      defined_tokens[tag] = token_args
    else
      # Check if the arguments are the same in both vectors
      if sort(defined_tokens[tag], by=x->x.name) != sort(token_args, by=x->x.name)
        error("Token $tag has been redefined with different arguments")
      end
    end

    # Check for duplicate arguments
    argnames = [t.name for t in token_args]
    not_unique = [a for a in argnames if count(x->x==a, argnames) > 1]
    if length(not_unique) != 0
      error("Token $tag has duplicate arguments: $not_unique")
    end

    push!(returned_tokens, LexerTokenDefinition(tag, token_args))
  end
  return returned_tokens
end

function retrieve_tokens_from_lexer(lexer::Lexer)::Vector{LexerTokenDefinition}
  return retrieve_tokens_from_actions(lexer.actions)
end
