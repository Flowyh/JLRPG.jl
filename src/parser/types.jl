using Parameters: @consts

@consts begin
  EMPTY_PRODUCTION::Vector{Symbol} = [Symbol(raw"%empty")]
  EMPTY_SYMBOL::Symbol = Symbol(raw"%empty")
  END_OF_INPUT::Symbol = Symbol(raw"%end")
  AUGMENTED_START::Symbol = Symbol(raw"%start")
end

# === Parser definition ===

"""
Parser production definition.

A parser production is a rule of the form:
```
A -> B1 B2 ... Bn

# or if the production is an alternative to previous production
A -> B1 B2 ... Bn
   | C1 C2 ... Cm
```

where A is a nonterminal and B1, B2, ..., Bn (C1, C2, ..., Cn) is a string
of grammar symbols (terminals or nonterminals).

The action is an optional string of Julia code that is executed when the production is
reduced. The action can be used to build an AST or to execute arbitrary code.

The return type is the type of the value returned by the action. If the action
is not defined, the return type is `nothing`.
"""
struct ParserProduction <: Comparable
  lhs::Symbol
  rhs::Vector{Symbol}
  action::Union{Nothing, String}
  return_type::Symbol

  function ParserProduction(
    lhs::Symbol,
    rhs::Vector{Symbol},
    action::Union{Nothing, AbstractString} = nothing,
    return_type::Symbol = :Nothing
  )::ParserProduction
    return new(lhs, rhs, action, return_type)
  end
end

@enum ParserType begin
  SLR
  LALR
  LR
end
ParserTypeFromSymbol::Dict{Symbol, ParserType} = Dict(
  :SLR => SLR,
  :LR => LR,
  :LALR => LALR,
)

"""
Parser options definition.

Currently only `tag`, `parser_tag` and `parser_type` options are supported.
Option `tag` defines a tag that will be preprended to all objects generated in the parser file.
Option `lexer_tag` defines a tag that will be preprended to all objects generated associated
with the lexer in the parser file.
Option `parser_type` defines the type of the parser to be generated (SLR, LALR or LR).
"""
struct ParserOptions <: Comparable
  parser_type::ParserType
  tag::String
  lexer_tag::String

  function ParserOptions(
    options::Dict = Dict()
  )::ParserOptions
    return new(
      get(options, :parser_type, SLR),
      get(options, :tag, "__PAR__"),
      get(options, :lexer_tag, "__LEX__")
    )
  end
end

"""
Parser definition.

Created by `read_parser_definition_file` function.
"""
struct Parser <: Comparable
  terminals::Vector{Symbol}
  nonterminals::Vector{Symbol}
  starting::Symbol
  productions::Dict{Symbol, Vector{ParserProduction}}
  symbol_types::Dict{Symbol, Symbol}
  lexer_tokens::Set{Symbol}
  lexer_token_aliases::Dict{Symbol, Symbol}
  code_blocks::Vector{String}
  options::ParserOptions
end

# Helper kwargs constructor
function Parser(;
  terminals::Vector{Symbol},
  nonterminals::Vector{Symbol},
  starting::Symbol,
  productions::Dict{Symbol, Vector{ParserProduction}},
  symbol_types::Dict{Symbol, Symbol},
  lexer_tokens::Set{Symbol},
  lexer_token_aliases::Dict{Symbol, Symbol},
  code_blocks::Vector{String},
  options::ParserOptions
)::Parser
  return Parser(
    terminals,
    nonterminals,
    starting,
    productions,
    symbol_types,
    lexer_tokens,
    lexer_token_aliases,
    code_blocks,
    options,
  )
end

"""
    parser_grammar_symbols(parser::Parser)

Concatenate parser nonterminals and terminals into a single vector.
"""
function parser_grammar_symbols(
  parser::Parser
)::Vector{Symbol}
  return vcat(parser.nonterminals, parser.terminals)
end
precompile(parser_grammar_symbols, (Parser,))

"""
    augment_productions(
      starting::Symbol,
      starting_return_type::Symbol,
      productions::Dict{Symbol, Vector{ParserProduction}}
    )::Dict{Symbol, Vector{ParserProduction}}

Add the augmented start production to the set of productions.

The augmented start production is of the form:
```
%start -> starting
```

where starting is the starting nonterminal of the parser.
"""
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
precompile(augment_productions, (Symbol, Symbol, Dict{Symbol, Vector{ParserProduction}}))

"""
    augment_parser(parser::Parser)::Parser

Augment the parser with the augmented start production.

Add the %start nonterminal to the set of nonterminals and the augmented start production
to the set of productions.
"""
function augment_parser(
  parser::Parser
)::Parser
  augmented_symbol_types::Dict{Symbol, Symbol} = copy(parser.symbol_types)
  augmented_symbol_types[AUGMENTED_START] = augmented_symbol_types[parser.starting]

  return Parser(
    vcat(parser.terminals, [END_OF_INPUT]),
    parser.nonterminals,
    parser.starting,
    augment_productions(parser.starting, parser.symbol_types[parser.starting], parser.productions),
    augmented_symbol_types,
    parser.lexer_tokens,
    parser.lexer_token_aliases,
    parser.code_blocks,
    parser.options,
  )
end
precompile(augment_parser, (Parser,))

# === Parsing tables ===

"""
Parsing item definition.

Used for the construction of the parsing table.
"""
struct ParsingItem <: Comparable
  lhs::Symbol
  production::Int
  dot::Int
  lookahead::Union{Nothing, Symbol}

  function ParsingItem(
    lhs::Symbol,
    production::Int;
    dot::Int = 0,
    lookahead::Union{Nothing, Symbol} = nothing
  )
    return new(lhs, production, dot, lookahead)
  end
end

"""
Parsing table action definition.

There are three types of actions:
- Shift
- Reduce
- Accept

The action is executed when the parser is in a certain state and reads a certain symbol.
"""
abstract type ParsingTableAction <: Comparable end

struct Shift <: ParsingTableAction
  state::Int
end

struct Reduce <: ParsingTableAction
  lhs::Symbol
  production::Int
end

struct Accept <: ParsingTableAction end
struct ParsingError <: ParsingTableAction end

"""
Parsing table definition.

The parsing table is used by the parser to decide what action to take
when it is in a certain state and reads a certain symbol.

All parsing table types have the same structure, but they differ
in its content.
"""
struct ParsingTable <: Comparable
  action::Dict{Int, Dict{Symbol, ParsingTableAction}}
  goto::Dict{Int, Dict{Symbol, Int}}
end
