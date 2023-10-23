using Mustache
using Parameters: @consts

@consts begin
  TEMPLATE_PATH::String = joinpath(@__DIR__, "simple_lexer.template")
end

# Read lexer_template.jl and fill mustache template
function fill_lexer_template(
  tokens::Vector{TokenDefinition},
  codeblocks::Vector{String},
  actions::Vector{Action}
)::String
  mustache_tokens = Mustache.load(TEMPLATE_PATH)
  env_setup = read(joinpath(@__DIR__, "environment_setup.jl"), String)
  rendered = Mustache.render(mustache_tokens,
    tokens = tokens,
    codeblocks = codeblocks,
    actions = actions,
    counter = counter,
    reset_counter = reset_counter,
    env = env_setup
  )
  reset_counter()
  return rendered
end

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
