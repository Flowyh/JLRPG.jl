function nullable(productions::Vector{ParserProduction})::Bool
  for production in productions
    if production.rhs == EMPTY_PRODUCTION
      return true
    end
  end
  return false
end

function first_sets(parser::Parser)::Dict{Symbol, Set{Symbol}}
  _first_sets::Dict{Symbol, Set{Symbol}} = Dict()
  _prev::Dict{Symbol, Set{Symbol}} = Dict()

  # Repeat until first sets stop changing
  while true
    for nonterminal in parser.nonterminals
      _first_sets[nonterminal] = _first_set_for_symbol(
        nonterminal,
        _prev,
        parser
      )
    end

    if _first_sets == _prev
      break
    end

    _prev = copy(_first_sets)
  end

  return _first_sets
end

# If production is A -> %empty, then add %empty to first(A)
# If production is A -> B1 B2 ... Bn, then add first(B1) to first(A)
# If production is A -> B1 B2 ... Bn and first(B1) contains %empty, then add first(B1) / %empty to first(A),
# and add first(B2) to first(A)
# If all first(Bi) contain %empty, then add %empty to first(A)
function _first_set_for_symbol(
  symbol::Symbol,
  prev_firsts::Dict{Symbol, Set{Symbol}},
  parser::Parser,
)::Set{Symbol}
  if symbol in parser.terminals
    return Set(symbol)
  end

  firsts::Set{Symbol} = get(prev_firsts, symbol, Set())
  for production in parser.productions[symbol]
    if production.rhs == EMPTY_PRODUCTION
      push!(firsts, EMPTY_SYMBOL)
    else
      all_nullable::Bool = true
      for rhs_symbol in production.rhs
        rhs_first_set::Set{Symbol} = get(prev_firsts, rhs_symbol, Set())
        if rhs_symbol == symbol
          # If production is A -> A B1 B2 ... Bn, and does not have an empty
          # production, then skip it
          # Otherwise, just check next symbol
          if !(EMPTY_SYMBOL in rhs_first_set)
            all_nullable = false
            break
          else
            continue
          end
        end
        union!(rhs_first_set, _first_set_for_symbol(rhs_symbol, prev_firsts, parser))
        union!(firsts, setdiff(rhs_first_set, EMPTY_SYMBOL))
        if !(EMPTY_SYMBOL in rhs_first_set)
          all_nullable = false
          break
        end
      end
      if all_nullable
        push!(firsts, EMPTY_SYMBOL)
      end
    end
  end

  return firsts
end

function _first_set_for_string_of_symbols(
  symbols::Vector{Symbol},
  firsts::Dict{Symbol, Set{Symbol}},
)::Set{Symbol}
  first_set::Set{Symbol} = Set()
  for symbol in symbols
    union!(first_set, firsts[symbol])
    if !(EMPTY_SYMBOL in firsts[symbol])
      break
    end
  end
  return first_set
end

function follow_sets(
  firsts::Dict{Symbol, Set{Symbol}},
  parser::Parser
)::Dict{Symbol, Set{Symbol}}
  _follow_sets::Dict{Symbol, Set{Symbol}} = Dict(
    parser.starting => Set(END_OF_INPUT)
  )
  _prev::Dict{Symbol, Set{Symbol}} = Dict()

  # Repeat until first sets stop changing
  while true
    for nonterminal in parser.nonterminals
      for production in parser.productions[nonterminal]
        if !haskey(_follow_sets, nonterminal)
          _follow_sets[nonterminal] = Set()
        end
        mergewith!(
          union,
          _follow_sets,
          _follows_from_prodcution(
            production,
            _prev,
            firsts,
            parser,
          )
        )
      end
    end

    if _follow_sets == _prev
      break
    end

    _prev = copy(_follow_sets)
  end

  return _follow_sets
end

function _follows_from_prodcution(
  production::ParserProduction,
  prev_follows::Dict{Symbol, Set{Symbol}},
  firsts::Dict{Symbol, Set{Symbol}},
  parser::Parser,
)::Dict{Symbol, Set{Symbol}}
  follow::Dict{Symbol, Set{Symbol}} = copy(prev_follows)
  still_nullable::Bool = true
  lhs::Symbol, rhs::Vector{Symbol} = production.lhs, production.rhs

  # If A -> aB is a production, then add follow(A) to follow(B)
  if rhs[end] in parser.nonterminals
    if !haskey(follow, rhs[end])
      follow[rhs[end]] = Set()
    end
    union!(follow[rhs[end]], get(prev_follows, lhs, Set()))
  else
    still_nullable = false
  end

  # Go from the end of the production to the beginning
  # If suffix is nullable, then add follow(lhs) to follow(curr)
  for id in length(rhs)-1:-1:1
    rhs_symbol = rhs[id]
    if rhs_symbol in parser.terminals
      still_nullable = false
      continue
    end

    if !haskey(follow, rhs_symbol)
      follow[rhs_symbol] = Set()
    end

    if still_nullable
      union!(follow[rhs_symbol], get(prev_follows, lhs, Set()))
    end

    if !(EMPTY_SYMBOL in firsts[rhs_symbol])
      still_nullable = false
    end

    trailing::Symbol = rhs[id+1]
    if trailing in parser.terminals
      push!(follow[rhs_symbol], trailing)
    else
      union!(follow[rhs_symbol], setdiff(
        _first_set_for_string_of_symbols(rhs[id+1:end], firsts),
        EMPTY_SYMBOL
      ))
    end
  end

  return follow
end
