using Parameters: @consts

@consts begin
  EMPTY_PRODUCTION::Vector{Symbol} = [Symbol(raw"%empty")]
  EMPTY_SYMBOL::Symbol = Symbol(raw"%empty")
  END_OF_INPUT::Symbol = Symbol(raw"%end")
end

# === Parser definition ===

struct ParserProduction <: Comparable
  lhs::Symbol
  rhs::Vector{Symbol}
  action::Union{Nothing, String}
  return_type::Symbol
end

struct ParserOptions <: Comparable
  # TODO: Fill if needed
end

struct Parser <: Comparable
  terminals::Set{Symbol}
  nonterminals::Set{Symbol}
  starting::Symbol
  productions::Dict{Symbol, Vector{ParserProduction}}
  symbol_types::Dict{Symbol, Symbol}
  tokens::Set{Symbol}
  token_aliases::Dict{Symbol, Symbol}
  code_blocks::Vector{String}
  options::ParserOptions
end
