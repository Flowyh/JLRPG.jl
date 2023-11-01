# === Lexer definition ===

struct RegexAlias
  name::Symbol
  pattern::String
end

struct LexerAction
  pattern::String
  body::String
end

struct LexerOptions
  # TODO: Fill if needed
end

struct Lexer <: Comparable
  actions::Vector{LexerAction}
  aliases::Vector{RegexAlias}
  code_blocks::Vector{String} # TODO: Add some more context to code blocks (origin file, line number etc.)
  options::LexerOptions
end

# === Generated lexer tokens ===

struct LexerTokenDefinition <: Comparable
  name::Symbol
  arguments::Vector{NamedTuple}
end

# By default, all LexerTokens will inherit this type and have some default members
# This is required for codegen, since the library user should not worry about creating all Token types manually
# Example of a token:
# struct Num <: LexerToken
#   tag::Symbol  # This is the name of the token
#   values::Dict # Dict of all values passed during token creation
#                # Those values may be typed, but it is not required
#                # You can access those values by using simple member access notation (token.value)
#   ???          # Anything else I might think of in the future
# end
abstract type LexerToken <: Comparable end

function tag(token::LexerToken)::Symbol
  return token.tag
end

# Support for member access notation
function Base.getproperty(token::LexerToken, name::Symbol)
  return getfield(token, values)[name]
end

# Return values dictionary
function values(token::LexerToken)::Dict
  return getfield(token, values)
end

#=== Mustache helpers ===#
# Generate convert method for each struct that will be used during mustache rendering
for _struct in (:LexerAction, :LexerTokenDefinition)
  @eval Base.convert(::Type{String}, _s::$_struct)::String = repr(_s)
end
