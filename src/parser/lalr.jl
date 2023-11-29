function lr1_cores(
  lr1_item_sets::Vector{Vector{ParsingItem}}
)::Vector{Vector{ParsingItem}}
  lr1_cores::Vector{Vector{ParsingItem}} = []
  for item_set in lr1_item_sets
    core::Vector{ParsingItem} = []
    for item in item_set
      push!(core, ParsingItem(item.lhs, item.production))
    end
    push!(lr1_cores, unique(core))
  end
  return lr1_cores
end

# TODO: change sets to mappings (for all same_cores => length(merged_lr1_item_sets))
function merge_lr1_cores(
  lr1_item_sets::Vector{Vector{ParsingItem}},
  lr1_gotos::Dict{Int, Dict{Symbol, Int}},
  lr1_cores::Vector{Vector{ParsingItem}}
)::Tuple
  merged_lr1_item_sets::Vector{Vector{ParsingItem}} = []
  merged_lr1_gotos::Dict{Int, Dict{Symbol, Int}} = Dict()

  merged_items::Int = 0
  merged_mappings::Dict{Int, Int} = Dict()
  already_merged::BitArray = falses(length(lr1_item_sets))

  for (i, core) in enumerate(lr1_cores)
    # Omit already merged cores
    if already_merged[i]
      continue
    end

    same_cores = findall(x -> issetequal(x, core), lr1_cores)

    # If there are more than one core with the same core, merge them
    if length(same_cores) > 1
      # Mark the cores as already merged
      for j in same_cores
        already_merged[j] = true
      end

      # Merge the cores
      merged_item_set::Vector{ParsingItem} = union(
        [lr1_item_sets[j] for j in same_cores]...
      )

      # Update the merged item sets
      push!(merged_lr1_item_sets, merged_item_set)
      for j in same_cores
        merged_mappings[j - 1] = merged_items
      end

      # Merge gotos
      merged_gotos = merge([get(lr1_gotos, j - 1, Dict()) for j in same_cores]...)
      if !isempty(merged_gotos)
        merged_lr1_gotos[merged_items] = merged_gotos
      end
    else # Just copy the core if it is unique
      push!(merged_lr1_item_sets, lr1_item_sets[i])
      merged_mappings[i - 1] = merged_items

      if haskey(lr1_gotos, i - 1)
        merged_lr1_gotos[merged_items] = lr1_gotos[i - 1]
      end
    end
    merged_items += 1
  end

  return merged_lr1_item_sets, merged_lr1_gotos, merged_mappings
end

function merge_lr1_gotos(
  lr1_gotos::Dict{Int, Dict{Symbol, Int}},
  merged_mappings::Dict{Int, Int}
)::Dict{Int, Dict{Symbol, Int}}
  merged_gotos::Dict{Int, Dict{Symbol, Int}} = Dict()
  for (from, gotos) in lr1_gotos
    for (symbol, to) in gotos
      merged_from = merged_mappings[from]
      merged_to = merged_mappings[to]
      if !haskey(merged_gotos, merged_from)
        merged_gotos[merged_from] = Dict()
      end
      merged_gotos[merged_from][symbol] = merged_to
    end
  end

  return merged_gotos
end

function LalrParsingTable(
  augmented_parser::Parser
)::ParsingTable
  terminals, nonterminals = augmented_parser.terminals, augmented_parser.nonterminals
  productions = augmented_parser.productions
  grammar_symbols = parser_grammar_symbols(augmented_parser)

  _first = first_sets(
    terminals,
    nonterminals,
    productions,
  )

  _lr1_item_sets, _lr1_gotos = lr1_items(productions, nonterminals, grammar_symbols, _first)
  _lr1_cores = lr1_cores(_lr1_item_sets)
  # Replace item sets and gotos with merged ones
  lr1_item_sets, lr1_gotos, merged_mappings = merge_lr1_cores(
    _lr1_item_sets,
    _lr1_gotos,
    _lr1_cores
  )

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
          to_shift::Int = lr1_gotos[i][next_symbol]
          if haskey(action[i], next_symbol) && action[i][next_symbol] != Shift(merged_mappings[to_shift])
            error(
              "Conflict in parsing table. " *
              "Shift-$(typeof(action[i][next_symbol])) conflict at state $i, " *
              "symbol $next_symbol.\nCurrent action $(action[i][next_symbol]), " *
              "new action: Shift($(merged_mappings[to_shift]))."
            )
          end
          action[i][next_symbol] = Shift(merged_mappings[to_shift])
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
        if !haskey(goto, merged_mappings[from])
          goto[merged_mappings[from]] = Dict()
        end
        goto[merged_mappings[from]][symbol] = merged_mappings[to]
      end
    end
  end

  return ParsingTable(action, goto)
end
