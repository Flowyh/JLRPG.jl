using Parameters: @consts

@consts begin
  RETURNED_TOKEN_PATTERN = r"return (?<tag>\w+)\((?<args>.*)\)"
  # TODO: Fix this regex, because it's ugly and fragile
  TOKEN_ARGUMENT_PATTERN = r"(?:(?<argname>.*?)(?:::(?<type>\w+))(?:\s*=\s*))?(?<value>[^,]+)(?:,\s+)?"
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
# Currently, you have to specify the type of each named argument, but I might change that in the future
# By default, if a token has only one argument, it will be named "value"
function retrieve_tokens_from_actions(actions::Vector{Action})::Vector{TokenDefinition}
  defined_tokens::Dict{Symbol, Dict} = Dict()
  returned_tokens::Vector{TokenDefinition} = []

  for action in actions
    body = action.body
    m = match(RETURNED_TOKEN_PATTERN, body)
    if m === nothing
      continue
    end

    tag = Symbol(m[:tag])
    arguments = eachmatch(TOKEN_ARGUMENT_PATTERN, m[:args]) |> collect
    no_arguments = length(arguments)

    if !haskey(defined_tokens, tag)
      defined_tokens[tag] = Dict()
    end

    for (i, argument) in enumerate(arguments)
      argname = Symbol(argument[:argname])
      type = Symbol(argument[:type])
      value = argument[:value]
      if argname === :nothing || argname === Symbol("")
        argname = Symbol("value$(no_arguments == 1 ? "" : i)")
      end
      if type === :nothing # TODO: Support no type at all
        type = :String
      end
      if haskey(defined_tokens[tag], argname) && defined_tokens[tag][argname] !== type
        error(
          "Argument $argname of token $tag has already been " *
          "defined with type $(defined_tokens[tag][argname])"
        )
      end
      defined_tokens[tag][argname] = (type, value)
    end

    push!(returned_tokens, TokenDefinition(tag, defined_tokens[tag]))
  end
  return returned_tokens
end

function retrieve_tokens_from_lexer(lexer::Lexer)::Vector{TokenDefinition}
  return retrieve_tokens_from_actions(lexer.actions)
end