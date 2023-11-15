function __PAR__simulate(
  tokens::Vector{LexerToken},
  table::ParsingTable
)
  @debug "<<<<< START OF PARSER SIMULATION >>>>>"
  states::Vector{Int} = [0] # Stack
  symbols::Vector = [] # Stack
  cursor::Int = 1
  current_symbol::Symbol = token_symbol(tokens[cursor])
  while true
    @debug "Current symbol: $current_symbol"
    @debug "States stack: $states"

    s::Int = states[end]
    current_action::ParsingTableAction = get(table.action[s], current_symbol, ParsingError())

    if current_action isa Shift
      @debug "Shift to state $(current_action.state)"

      push!(states, current_action.state)
      push!(symbols, tokens[cursor])
      cursor += 1
      current_symbol = token_symbol(tokens[cursor])
    elseif current_action isa Reduce
      lhs, production = current_action.lhs, current_action.production
      @debug "Reduce with production $(lhs), $(production)"

      symbols_slice::Vector = []
      for _ in 1:LHS_ID_TO_RHS_LENGTH[lhs][production]
        pop!(states)
        pushfirst!(symbols_slice, pop!(symbols)) # Push first for convenience of indexing with $1, $2, ...
      end
      s = states[end]
      push!(states, table.goto[s][lhs])
      returned_symbol = LHS_ID_TO_ACTION[lhs][production](symbols_slice)
      push!(symbols, returned_symbol)
    elseif current_action isa Accept
      @debug "Accept!"
      break
    elseif current_action isa ParsingError
      if tokens[cursor] isa __LEX__EOI
        error("Syntax error at end of input")
      else
        error("Syntax error at token $(tokens[cursor])")
      end
    end
  end

  @debug "<<<<<   END OF PARSER SIMULATION >>>>>"
end