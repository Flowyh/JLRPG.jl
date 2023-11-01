# === Parser definition ===

struct Parser
  terminals::Set{Symbol}
  nonterminals::Set{Symbol}
  starting::Symbol
  productions::Dict{Symbol, Production}
  symbol_types::Dict{Symbol, Symbol}
  tokens::Set{Token}
  token_aliases::Dict{String, Token}
  code_blocks::Vector{String}
  options::Options
end

struct Options
  # TODO: Fill if needed
end

struct Token
  name::Symbol
  alias::Union{Nothing, String}
end

struct Production
  symbol::Symbol
  production::Vector{Symbol}
  action::Union{Nothing, String}
  return_type::Symbol
end
