function __PAR__simulate(
  tokens::Vector{LexerToken},
  table::ParsingTable
)
  states::Vector{Int} = [0] # Stack
  cursor::Int = 1
  current_symbol::Symbol = symbol(tokens[cursor])
  while true
    s::Int = states[end]
    current_action::ParsingTableAction = table.action[s][current_symbol]

    if current_action isa Shift
      push!(states, current_action.state)
      cursor += 1
      current_symbol = symbol(tokens[cursor])
    elseif current_action isa Reduce
      lhs, production = current_action.lhs, current_action.production
      for _ in 1:length(LHS_ID_TO_RHS_LENGTH[lhs][production])
        pop!(states)
      end
      s = states[end]
      push!(states, table.goto[s][lhs])
      LHS_ID_TO_ACTION[lhs][production]()
    elseif current_action isa Accept
      break
    else
      error("Syntax error at token $(tokens[cursor])")
    end
  end
end