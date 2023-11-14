using Mustache
using Parameters: @consts

@consts begin
  TEMPLATE_PATH::String = joinpath(@__DIR__, "template/parser.template")

  __PAR__ENV = read(joinpath(@__DIR__, "template/environment_setup.jl"), String)
  __PAR__SIMULATION = read(joinpath(@__DIR__, "template/simulation_setup.jl"), String)
  __PAR__MAIN = read(joinpath(@__DIR__, "template/main_setup.jl"), String)
end

function fill_parser_template(
  codeblocks::Vector{String},
  table::ParsingTable,
  productions::Dict{Symbol, Vector{ParserProduction}},
  symbol_types::Dict{Symbol, Symbol}
)::String
  mustache_tokens = Mustache.load(TEMPLATE_PATH)
  tupled_action, tupled_goto = parsing_table_to_named_tuples(table)

  rendered = Mustache.render(mustache_tokens,
    codeblocks = codeblocks,
    action = tupled_action,
    goto = tupled_goto,
    productions=productions_to_named_tuples(productions, symbol_types),
    env = __PAR__ENV,
    simulation = __PAR__SIMULATION,
    main = __PAR__MAIN
  )
  return rendered
end

function productions_to_named_tuples(
  productions::Dict{Symbol, Vector{ParserProduction}},
  symbol_types::Dict{Symbol, Symbol}
)::Vector{NamedTuple}
  actions::Vector{NamedTuple} = []
  for lhs in keys(productions)
    if lhs == AUGMENTED_START
      continue
    end
    push!(actions, (
      lhs=lhs,
      type=symbol_types[lhs],
      actions=[
        (id=id, rhs=join(prod.rhs, " "), action=prod.action)
        for (id, prod) in enumerate(productions[lhs])
      ],
      lengths=["$(length(prod.rhs))" for prod in productions[lhs]]
    ))
  end
  return actions
end

function parsing_table_to_named_tuples(
  table::ParsingTable
)::Tuple{Vector{NamedTuple}, Vector{NamedTuple}}
  tupled_action::Vector{NamedTuple} = []
  tupled_goto::Vector{NamedTuple} = []

  for state in keys(table.action)
    actions::Vector{NamedTuple} = []
    for (symbol, action) in table.action[state]
      push!(actions, (
        symbol=symbol,
        action=action
      ))
    end
    push!(tupled_action, (state=state, actions=actions))
  end

  for state in keys(table.goto)
    gotos::Vector{NamedTuple} = [
      (symbol=symbol, goto=goto)
      for (symbol, goto) in table.goto[state]
    ]
    push!(tupled_goto, (state=state, gotos=gotos))
  end

  return (tupled_action, tupled_goto)
end
