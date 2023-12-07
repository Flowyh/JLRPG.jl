"""
    lr1_kernels(lr1_item_sets::Vector{Vector{ParsingItem}})

Get the kernels of the LR(1) item sets (items without lookahead).
"""
function lr1_kernels(
  lr1_item_sets::Vector{Vector{ParsingItem}}
)::Vector{Vector{ParsingItem}}
  lr1_kernels::Vector{Vector{ParsingItem}} = []
  for item_set in lr1_item_sets
    core::Vector{ParsingItem} = []
    for item in item_set
      push!(core, ParsingItem(item.lhs, item.production))
    end
    push!(lr1_kernels, unique(core))
  end
  return lr1_kernels
end


"""
    merge_lr1_kernels(
      lr1_item_sets::Vector{Vector{ParsingItem}},
      lr1_gotos::Dict{Int, Dict{Symbol, Int}},
      lr1_kernels::Vector{Vector{ParsingItem}}
    )

Merge the LR(1) kernels that are equal.

Returns a tuple of the merged item sets, gotos and mappings from the old item
sets to the new ones.
"""
function merge_lr1_kernels(
  lr1_item_sets::Vector{Vector{ParsingItem}},
  lr1_gotos::Dict{Int, Dict{Symbol, Int}},
  lr1_kernels::Vector{Vector{ParsingItem}}
)::Tuple
  merged_lr1_item_sets::Vector{Vector{ParsingItem}} = []
  merged_lr1_gotos::Dict{Int, Dict{Symbol, Int}} = Dict()

  merged_items::Int = 0
  merged_mappings::Dict{Int, Int} = Dict()
  already_merged::BitArray = falses(length(lr1_item_sets))

  for (i, core) in enumerate(lr1_kernels)
    # Omit already merged kernels
    if already_merged[i]
      continue
    end

    same_kernels = findall(x -> issetequal(x, core), lr1_kernels)

    # If there are more than one core with the same core, merge them
    if length(same_kernels) > 1
      # Mark the kernels as already merged
      for j in same_kernels
        already_merged[j] = true
      end

      # Merge the kernels
      merged_item_set::Vector{ParsingItem} = union(
        [lr1_item_sets[j] for j in same_kernels]...
      )

      # Update the merged item sets
      push!(merged_lr1_item_sets, merged_item_set)
      for j in same_kernels
        merged_mappings[j - 1] = merged_items
      end

      # Merge gotos
      merged_gotos = merge([get(lr1_gotos, j - 1, Dict()) for j in same_kernels]...)
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

"""
    LalrParsingTable(augmented_parser::Parser)

Generate the LALR parsing table for the augmented parser.

The augmented parser is the parser with the augmented start production.

This algorithm computes the LR(1) item sets and gotos, then merges the item
sets that are equal. Finally, it generates the parsing table from the merged
item sets and gotos (and mappings).

This algorithm is almost the same as the one used for the LR(1) parsing table.
The procedure of generating the LR(1) table is described in the Dragon Book,
sections 4.7.2, 4.7.3. The idea of merging the item sets is described in the section 4.7.4.
"""
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
  _lr1_kernels = lr1_kernels(_lr1_item_sets)
  # Replace item sets and gotos with merged ones
  lr1_item_sets, lr1_gotos, merged_mappings = merge_lr1_kernels(
    _lr1_item_sets,
    _lr1_gotos,
    _lr1_kernels
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

#============#
# PRECOMPILE #
#============#
precompile(lr1_kernels, (
  Vector{Vector{ParsingItem}},
))
precompile(merge_lr1_kernels, (
  Vector{Vector{ParsingItem}},
  Dict{Int, Dict{Symbol, Int}},
  Vector{Vector{ParsingItem}},
))
precompile(LalrParsingTable, (Parser,))
