function __PAR__simulate(
  tokens::Vector{LexerToken},
  table::ParsingTable = __PAR__PARSING_TABLE
)
  @debug "<<<<< START OF PARSER SIMULATION >>>>>"
  states::Vector{Int} = [0] # Stack
  symbols::Vector = [] # Stack
  current_token::Int = 1
  current_symbol::Symbol = token_symbol(tokens[current_token])
  while true
    @debug "Current symbol: $current_symbol"
    @debug "States stack: $states"

    s::Int = states[end]
    current_action::ParsingTableAction = get(table.action[s], current_symbol, ParsingError())

    if current_action isa Shift
      @debug "Shift to state $(current_action.state)"

      push!(states, current_action.state)
      push!(symbols, tokens[current_token])
      current_token += 1
      current_symbol = token_symbol(tokens[current_token])
    elseif current_action isa Reduce
      lhs, production = current_action.lhs, current_action.production
      @debug "Reduce with production $(lhs), $(production)"

      symbols_slice::Vector = []
      for _ in 1:__PAR__LHS_ID_TO_RHS_LENGTH[lhs][production]
        pop!(states)
        pushfirst!(symbols_slice, pop!(symbols)) # Push first for convenience of indexing with $1, $2, ...
      end
      s = states[end]
      push!(states, table.goto[s][lhs])
      returned_symbol = __PAR__LHS_ID_TO_ACTION[lhs][production](symbols_slice)
      push!(symbols, returned_symbol)
    elseif current_action isa Accept
      @debug "Accept!"
      break
    elseif current_action isa ParsingError
      if token_symbol(tokens[current_token]) == END_OF_INPUT
        error("Not enough tokens to parse")
      else
        token = tokens[current_token]
        symbol = token_symbol(token)
        error(
          "Syntax error at token $symbol" * "\n" *
          "       Token $(sprint(show_simple, token)) at $(token_file_pos(token))"
        )
      end
    end
  end

  @debug "<<<<<   END OF PARSER SIMULATION >>>>>"
end