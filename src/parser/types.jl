using Parameters: @consts

@consts begin
  EMPTY_PRODUCTION::Vector{Symbol} = [Symbol(raw"%empty")]
  EMPTY_SYMBOL::Symbol = Symbol(raw"%empty")
  END_OF_INPUT::Symbol = Symbol(raw"%end")
  AUGMENTED_START::Symbol = Symbol(raw"%start")
end

# === Parser definition ===

struct ParserProduction <: Comparable
  lhs::Symbol
  rhs::Vector{Symbol}
  action::Union{Nothing, String}
  return_type::Symbol

  function ParserProduction(
    lhs::Symbol,
    rhs::Vector{Symbol},
    action::Union{Nothing, AbstractString} = nothing,
    return_type::Symbol = :nothing
  )::ParserProduction
    return new(lhs, rhs, action, return_type)
  end
end


struct ParserOptions <: Comparable
  # TODO: Fill if needed
end

struct Parser <: Comparable
  terminals::Vector{Symbol}
  nonterminals::Vector{Symbol}
  starting::Symbol
  productions::Dict{Symbol, Vector{ParserProduction}}
  symbol_types::Dict{Symbol, Symbol}
  tokens::Set{Symbol}
  token_aliases::Dict{Symbol, Symbol}
  code_blocks::Vector{String}
  options::ParserOptions
end

function Parser(;
  terminals::Vector{Symbol},
  nonterminals::Vector{Symbol},
  starting::Symbol,
  productions::Dict{Symbol, Vector{ParserProduction}},
  symbol_types::Dict{Symbol, Symbol},
  tokens::Set{Symbol},
  token_aliases::Dict{Symbol, Symbol},
  code_blocks::Vector{String},
  options::ParserOptions
)::Parser
  return Parser(
    terminals,
    nonterminals,
    starting,
    productions,
    symbol_types,
    tokens,
    token_aliases,
    code_blocks,
    options,
  )
end

function parser_grammar_symbols(
  parser::Parser
)::Vector{Symbol}
  return vcat(parser.nonterminals, parser.terminals)
end

function augment_productions(
  starting::Symbol,
  starting_return_type::Symbol,
  productions::Dict{Symbol, Vector{ParserProduction}}
)::Dict{Symbol, Vector{ParserProduction}}
  augmented_productions::Dict{Symbol, Vector{ParserProduction}} = copy(productions)
  augmented_productions[AUGMENTED_START] = []
  push!(
    augmented_productions[AUGMENTED_START],
    ParserProduction(
      AUGMENTED_START,
      [starting],
      nothing,
      starting_return_type,
    )
  )

  return augmented_productions
end

function augment_parser(
  parser::Parser
)::Parser
  return Parser(
    parser.terminals,
    parser.nonterminals,
    parser.starting,
    augment_productions(parser.starting, parser.symbol_types[parser.starting], parser.productions),
    parser.symbol_types,
    parser.tokens,
    parser.token_aliases,
    parser.code_blocks,
    parser.options,
  )
end

# === Parsing tables ===

struct ParsingItem <: Comparable
  lhs::Symbol
  production::Int
  dot::Int
  lookaheads::Set{Symbol}

  function ParsingItem(
    lhs::Symbol,
    production::Int,
    dot::Int = 0,
    lookaheads::Set{Symbol} = Set{Symbol}()
  )
    return new(lhs, production, dot, lookaheads)
  end
end

abstract type ParsingTableAction <: Comparable end

struct Shift <: ParsingTableAction
  state::Int
end

struct Reduce <: ParsingTableAction
  lhs::Symbol
  production::Int
end

struct Accept <: ParsingTableAction end
struct Error <: ParsingTableAction end

struct ParsingTable <: Comparable
  action::Dict{Int, Dict{Symbol, ParsingTableAction}}
  goto::Dict{Int, Dict{Symbol, Int}}
end
