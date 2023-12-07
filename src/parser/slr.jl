"""
    lr0_closure(
      items::Vector{ParsingItem},
      productions::Dict{Symbol, Vector{ParserProduction}},
      nonterminals::Vector{Symbol}
    )::Vector{ParsingItem}

Compute the LR(0) closure of a set of items.

The procedure is described in the Dragon Book, 2nd edition, section 4.6.2.
"""
function lr0_closure(
  items::Vector{ParsingItem},
  productions::Dict{Symbol, Vector{ParserProduction}},
  nonterminals::Vector{Symbol}
)::Vector{ParsingItem}
  new_items::Vector{ParsingItem} = copy(items)

  while true
    has_changed::Bool = false

    for item in new_items
      lhs, id, dot = item.lhs, item.production, item.dot
      rhs = productions[lhs][id].rhs

      # Dot at the end of production
      if dot == length(rhs)
        continue
      end

      next_symbol_index::Int = dot + 1
      next_symbol::Symbol = rhs[next_symbol_index]
      if next_symbol in nonterminals
        for id in eachindex(productions[next_symbol])
          new_item = ParsingItem(next_symbol, id)
          if !(new_item in new_items)
            push!(new_items, new_item)
            has_changed = true
          end
        end
      end
    end

    if !has_changed
      break
    end
  end

  return new_items
end

"""
    lr0_goto(
      items::Vector{ParsingItem},
      symbol::Symbol,
      productions::Dict{Symbol, Vector{ParserProduction}},
      nonterminals::Vector{Symbol}
    )::Vector{ParsingItem}

Compute the LR(0) goto of a set of items.

The procedure is described in the Dragon Book, 2nd edition, section 4.6.2.
"""
function lr0_goto(
  items::Vector{ParsingItem},
  symbol::Symbol,
  productions::Dict{Symbol, Vector{ParserProduction}},
  nonterminals::Vector{Symbol}
)::Vector{ParsingItem}
  new_items::Vector{ParsingItem} = []

  for item in items
    lhs, id, dot = item.lhs, item.production, item.dot
    rhs = productions[lhs][id].rhs

    # Dot at the end of production
    if dot == length(rhs)
      continue
    end

    next_symbol_index::Int = dot + 1
    next_symbol::Symbol = rhs[next_symbol_index]
    if next_symbol == symbol
      push!(new_items, ParsingItem(lhs, id; dot=next_symbol_index))
    end
  end

  return lr0_closure(new_items, productions, nonterminals)
end

"""
    lr0_items(
      augmented_productions::Dict{Symbol, Vector{ParserProduction}},
      nonterminals::Vector{Symbol},
      grammar_symbols::Vector{Symbol}
    )::Tuple{Vector{Vector{ParsingItem}}, Dict{Int, Dict{Symbol, Int}}}

Compute the LR(0) items for the given grammar.

The procedure is described in the Dragon Book, 2nd edition, section 4.6.2.
"""
function lr0_items(
  augmented_productions::Dict{Symbol, Vector{ParserProduction}},
  nonterminals::Vector{Symbol},
  grammar_symbols::Vector{Symbol}
)::Tuple{Vector{Vector{ParsingItem}}, Dict{Int, Dict{Symbol, Int}}}
  if !haskey(augmented_productions, AUGMENTED_START)
    error("Parser must have an augmented start production")
  end

  lr0_item_sets::Vector{Vector{ParsingItem}} = [
    lr0_closure(
      [ParsingItem(AUGMENTED_START, 1)],
      augmented_productions,
      nonterminals,
    )
  ]
  lr0_gotos::Dict{Int, Dict{Symbol, Int}} = Dict()

  while true
    has_changed::Bool = false

    for (id, items) in enumerate(lr0_item_sets)
      for symbol in grammar_symbols
        next_set = lr0_goto(items, symbol, augmented_productions, nonterminals)
        if !isempty(next_set)
          if !(next_set in lr0_item_sets)
            push!(lr0_item_sets, next_set)
            has_changed = true
          end

          # Update gotos
          from::Int = id - 1
          to::Int = findfirst(isequal(next_set), lr0_item_sets) - 1
          if !haskey(lr0_gotos, from)
            lr0_gotos[from] = Dict()
          end
          if !haskey(lr0_gotos[from], symbol)
            lr0_gotos[from][symbol] = to
          end
        end
      end
    end

    if !has_changed
      break
    end
  end

  return lr0_item_sets, lr0_gotos
end

"""
    SlrParsingTable(augmented_parser::Parser)

Generate the SLR parsing table for the augmented parser.

The augmented parser is the parser with the augmented start production.

The procedure is described in the Dragon Book, 2nd edition, section 4.6.4.
"""
function SlrParsingTable(
  augmented_parser::Parser
)::ParsingTable
  terminals, nonterminals = augmented_parser.terminals, augmented_parser.nonterminals
  productions = augmented_parser.productions
  grammar_symbols = parser_grammar_symbols(augmented_parser)

  _first = first_sets(
    terminals,
    nonterminals,
    productions
  )
  _follow = follow_sets(
    _first,
    terminals,
    nonterminals,
    productions,
    augmented_parser.starting
  )

  lr0_item_sets, lr0_gotos = lr0_items(productions, nonterminals, grammar_symbols)

  action::Dict{Int, Dict{Symbol, ParsingTableAction}} = Dict()
  goto::Dict{Int, Dict{Symbol, Int}} = Dict()

  # (1) If A -> α·aβ is in I and goto(I, a) = J then set action[i, a] to "shift j"
  # (2) If A -> α· is in I, then set action[i, a] to "reduce A -> α" for all a in Follow(A), A != S'
  # (3) If S' -> S· is in I, then set action[i, $] to "accept"
  for (set_id, item_set) in enumerate(lr0_item_sets)
    i = set_id - 1
    action[i] = Dict()
    for item in item_set
      lhs, id, dot = item.lhs, item.production, item.dot
      rhs = productions[lhs][id].rhs

      if dot == length(rhs)
        if lhs == AUGMENTED_START # (3)
          action[i][END_OF_INPUT] = Accept()
        else # (2)
          for symbol in _follow[lhs]
            if haskey(action[i], symbol)
              error("Conflict in parsing table. $(typeof(action[i][symbol]))-Reduce conflict at state $i, symbol $symbol")
            end
            action[i][symbol] = Reduce(lhs, id)
          end
        end
      else # (1)
        next_symbol_index::Int = dot + 1
        next_symbol::Symbol = rhs[next_symbol_index]
        if next_symbol in augmented_parser.terminals && haskey(lr0_gotos, i) && haskey(lr0_gotos[i], next_symbol)
          if haskey(action[i], next_symbol) && action[i][next_symbol] != Shift(lr0_gotos[i][next_symbol])
            error(
              "Conflict in parsing table. " *
              "Shift-$(typeof(action[i][next_symbol])) conflict at state $i, " *
              "symbol $next_symbol.\nCurrent action $(action[i][next_symbol]), " *
              "new action: Shift($(lr0_gotos[i][next_symbol]))."
            )
          end
          action[i][next_symbol] = Shift(lr0_gotos[i][next_symbol])
        end
      end
    end

    if isempty(action[i])
      delete!(action, i)
    end
  end

  # (4) If goto(I, A) = J then set goto[i, A] to j, A is a nonterminal
  for (from, gotos) in lr0_gotos
    for (symbol, to) in gotos
      if symbol in augmented_parser.nonterminals
        if !haskey(goto, from)
          goto[from] = Dict()
        end
        goto[from][symbol] = to
      end
    end
  end

  return ParsingTable(action, goto)
end

#============#
# PRECOMPILE #
#============#
precompile(lr0_closure, (
  Vector{ParsingItem},
  Dict{Symbol, Vector{ParserProduction}},
  Vector{Symbol},
))
precompile(lr0_goto, (
  Vector{ParsingItem},
  Symbol,
  Dict{Symbol, Vector{ParserProduction}},
  Vector{Symbol},
))
precompile(lr0_items, (
  Dict{Symbol, Vector{ParserProduction}},
  Vector{Symbol},
  Vector{Symbol},
))
precompile(SlrParsingTable, (Parser,))
