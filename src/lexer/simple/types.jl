# === Lexer definition ===

struct RegexAlias
  name::Symbol
  pattern::String
end

struct Action
  pattern::String
  body::String
end

struct Options
  # TODO: Fill if needed
end

struct Lexer
  actions::Vector{Action}
  aliases::Vector{RegexAlias}
  code_blocks::Vector{String}
  options::Options
end

# === Lexer ===

abstract type LexerToken end

function tag(token::LexerToken)::Symbol
  return token.tag
end

function value(token::LexerToken) 
  return token.value
end
