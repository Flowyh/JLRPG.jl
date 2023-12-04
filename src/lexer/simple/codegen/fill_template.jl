using Mustache
using Parameters: @consts

@consts begin
  TEMPLATE_PATH::String = joinpath(@__DIR__, "template/simple_lexer.template")

  __LEX__ENV = read(joinpath(@__DIR__, "template/environment_setup.jl"), String)
  __LEX__TOKENIZE = read(joinpath(@__DIR__, "template/tokenize_setup.jl"), String)
  __LEX__MAIN = read(joinpath(@__DIR__, "template/main_setup.jl"), String)
end

function fill_lexer_template(
  tokens::Vector{LexerTokenDefinition},
  codeblocks::Vector{String},
  actions::Vector{LexerAction}
)::String
  mustache_tokens = Mustache.load(TEMPLATE_PATH)

  rendered = Mustache.render(mustache_tokens,
    tokens = tokens,
    codeblocks = codeblocks,
    actions = actions,
    counter = counter,
    reset_counter = reset_counter,
    env = __LEX__ENV,
    tokenize = __LEX__TOKENIZE,
    main = __LEX__MAIN
  )
  reset_counter()
  return rendered
end

# TODO: replace this dirty hack with some proper solution
# Counter for tagging action functions
let
  global counter
  global reset_counter
  no_actions = 0
  function counter(_...)
    no_actions += 1
    return no_actions
  end
  function reset_counter(_...)
    no_actions = 0
    return ""
  end
end
