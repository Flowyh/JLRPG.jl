function lr1_closure(
  items::Vector{ParsingItem},
  productions::Dict{Symbol, Vector{ParserProduction}},
  nonterminals::Vector{Symbol},
  firsts::Dict{Symbol, Set{Symbol}},
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
        trailing_symbols::Vector{Symbol} = vcat(rhs[next_symbol_index+1:end], [item.lookahead])
        lookaheads::Set{Symbol} = first_set_for_string_of_symbols(trailing_symbols, firsts)

        for lookahead in lookaheads
          for id in eachindex(productions[next_symbol])
              new_item = ParsingItem(next_symbol, id; lookahead=lookahead)
              if !(new_item in new_items)
                push!(new_items, new_item)
                has_changed = true
              end
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

function lr1_goto(
  items::Vector{ParsingItem},
  symbol::Symbol,
  productions::Dict{Symbol, Vector{ParserProduction}},
  nonterminals::Vector{Symbol},
  firsts::Dict{Symbol, Set{Symbol}},
)::Vector{ParsingItem}
  new_items::Vector{ParsingItem} = []

  for item in items
    lhs, id, dot = item.lhs, item.production, item.dot
    lookahead = item.lookahead
    rhs = productions[lhs][id].rhs

    # Dot at the end of production
    if dot == length(rhs)
      continue
    end

    next_symbol_index::Int = dot + 1
    next_symbol::Symbol = rhs[next_symbol_index]
    if next_symbol == symbol
      push!(
        new_items,
        ParsingItem(
          lhs, id;
          dot=next_symbol_index, lookahead=lookahead
        )
      )
    end
  end

  return lr1_closure(new_items, productions, nonterminals, firsts)
end

function lr1_items(
  augmented_productions::Dict{Symbol, Vector{ParserProduction}},
  nonterminals::Vector{Symbol},
  grammar_symbols::Vector{Symbol},
  firsts::Dict{Symbol, Set{Symbol}}
)::Tuple{Vector{Vector{ParsingItem}}, Dict{Int, Dict{Symbol, Int}}}
  if !haskey(augmented_productions, AUGMENTED_START)
    error("Parser must have an augmented start production")
  end

  lr1_item_sets::Vector{Vector{ParsingItem}} = [
    lr1_closure(
      [ParsingItem(AUGMENTED_START, 1, lookahead=END_OF_INPUT)],
      augmented_productions,
      nonterminals,
      firsts
    )
  ]
  lr1_gotos::Dict{Int, Dict{Symbol, Int}} = Dict()

  while true
    has_changed::Bool = false

    for (id, items) in enumerate(lr1_item_sets)
      for symbol in grammar_symbols
        next_set = lr1_goto(items, symbol, augmented_productions, nonterminals, firsts)
        if !isempty(next_set)
          if !(next_set in lr1_item_sets)
            push!(lr1_item_sets, next_set)
            has_changed = true
          end

          # Update gotos
          from::Int = id - 1
          to::Int = findfirst(isequal(next_set), lr1_item_sets) - 1
          if !haskey(lr1_gotos, from)
            lr1_gotos[from] = Dict()
          end
          if !haskey(lr1_gotos[from], symbol)
            lr1_gotos[from][symbol] = to
          end
        end
      end
    end

    if !has_changed
      break
    end
  end

  return lr1_item_sets, lr1_gotos
end

function LrParsingTable(
  augmented_parser::Parser
)::ParsingTable
  terminals, nonterminals = augmented_parser.terminals, augmented_parser.nonterminals
  productions = augmented_parser.productions

  _first = first_sets(
    terminals,
    nonterminals,
    productions,
  )

  grammar_symbols = parser_grammar_symbols(augmented_parser)
  lr1_item_sets, lr1_gotos = lr1_items(productions, nonterminals, grammar_symbols, _first)

  action::Dict{Int, Dict{Symbol, ParsingTableAction}} = Dict()
  goto::Dict{Int, Dict{Symbol, Int}} = Dict()

  # (1) [If A  -> α·aβ, b] is in I and goto(I, a) = J then set action[I, a] to "shift j"
  # (2) [If A  -> α·,   a] is in I, then set action[I, a] to "reduce A -> α"
  # (3) [If S' -> S·,   $] is in I, then set action[I, $] to "accept"
  for (set_id, item_set) in enumerate(lr1_item_sets)
    i = set_id - 1
    action[i] = Dict()
    goto[i] = Dict()
    for item in item_set
      lhs, id, dot = item.lhs, item.production, item.dot
      lookahead = item.lookahead
      rhs = productions[lhs][id].rhs

      if dot == length(rhs)
        if lhs == AUGMENTED_START && lookahead == END_OF_INPUT # (3)
          action[i][END_OF_INPUT] = Accept()
        else # (2)
          if haskey(action[i], lookahead)
            error("Conflict in parsing table. $(typeof(action[i][lookahead]))-Reduce conflict at state $i, symbol $lookahead")
          end
          action[i][lookahead] = Reduce(lhs, id)
        end
      else # (1)
        next_symbol_index::Int = dot + 1
        next_symbol::Symbol = rhs[next_symbol_index]
        if next_symbol in augmented_parser.terminals && haskey(lr1_gotos, i) && haskey(lr1_gotos[i], next_symbol)
          if haskey(action[i], next_symbol) && action[i][next_symbol] != Shift(lr1_gotos[i][next_symbol])
            error(
              "Conflict in parsing table. " *
              "Shift-$(typeof(action[i][next_symbol])) conflict at state $i, " *
              "symbol $next_symbol.\nCurrent action $(action[i][next_symbol]), " *
              "new action: Shift($(lr1_gotos[i][next_symbol]))."
            )
          end
          action[i][next_symbol] = Shift(lr1_gotos[i][next_symbol])
        end
      end
    end

    if isempty(action[i])
      delete!(action, i)
    end
    if isempty(goto[i])
      delete!(goto, i)
    end
  end

  # (4) If goto(I, A) = J then set goto[i, A] to j, A is a nonterminal
  for (from, gotos) in lr1_gotos
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
