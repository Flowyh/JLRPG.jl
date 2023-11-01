# === Parser definition ===

struct ParserProduction
  symbol::Symbol
  production::Vector{Symbol}
  action::Union{Nothing, String}
  return_type::Symbol
end

struct ParserOptions
  # TODO: Fill if needed
end

struct Parser
  terminals::Set{Symbol}
  nonterminals::Set{Symbol}
  starting::Symbol
  productions::Dict{Symbol, ParserProduction}
  symbol_types::Dict{Symbol, Symbol}
  tokens::Set{Symbol}
  token_aliases::Dict{Symbol, Symbol}
  code_blocks::Vector{String}
  options::ParserOptions
end
