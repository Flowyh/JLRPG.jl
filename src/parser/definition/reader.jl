using Parameters: @consts

@enum Section definitions productions code
@enum SpecialDefinition section code_block option token type start production production_alt comment

@consts begin
  SectionDelimiter::String = "%%"
  CodeBlockStart::String = "%{"
  CodeBlockEnd::String = "%}"

  SECTION_REGEX = r"%%"
  CODE_BLOCK_REGEX = r"%{((?s:.)*?)%}"
  OPTION_REGEX = r"%option[ \t]+((?:\w+ ?)+)"
  TOKEN_REGEX = r"%token[ \t]+(?<name>[A-Z0-9_-]+)(?:[ \t]+\"(?<alias>.+)\")?"
  TYPE_REGEX = r"%type[ \t]+<(?<type>\w+)>(?:[ \t]+(?<symbol>\w+))?"
  START_REGEX = r"%start[ \t]+(?<symbol>.+)"
  PRODUCTION_REGEX = r"(?<lhs>[a-z0-9_-]+)\s+->\s+(?<production>[A-Za-z0-9_-\s]+?)\s+{(?<action>(?s:.)*?)}"
  EMPTY_PRODUCTION_REGEX = r"(?<lhs>[a-z0-9_-]+)\s+->\s+(?<production>.+)"
  PRODUCTION_ALT_REGEX = r"\|\s+(?<production>.+)\s+?{(?<action>(?s:.)*?)}"
  EMPTY_PRODUCTION_ALT_REGEX = r"\|\s+(?<production>.+)"
  COMMENT_REGEX = r"#=[^\n]*=#\n?"

  SpecialDefinitionPatterns::Vector{Pair{SpecialDefinition, Regex}} = [
    section => SECTION_REGEX,
    code_block => CODE_BLOCK_REGEX,
    option => OPTION_REGEX,
    token => TOKEN_REGEX,
    type => TYPE_REGEX,
    start => START_REGEX,
    production => PRODUCTION_REGEX,
    production => EMPTY_PRODUCTION_REGEX,
    production_alt => PRODUCTION_ALT_REGEX,
    production_alt => EMPTY_PRODUCTION_ALT_REGEX,
    comment => COMMENT_REGEX
  ]
end

# Structure of a definition file:
#
# definitions/flags
# %%
# grammar productions
# %%
# user code
#
# Blocks enclosed with %{ and %} are copied to the output file (in the same order).

function read_definition_file(
  path::String
)::Parser
  parser::Union{Parser, Nothing} = nothing
  open(path) do file
    parser = _read_definition_file(file)
  end

  return parser::Parser
end

function _next_section(
  current::Section
)::Section
  if current == definitions
    return productions
  elseif current == productions
    return code
  end
end

function _section_guard(
  current::Section,
  expected::Section,
  err_msg::String
)
  if current != expected
    error(err_msg)
  end
end

islowercased(str::String)::Bool = ismatch(r"^[a-z0-9_-]+$", str)
isuppercased(str::String)::Bool = ismatch(r"^[A-Z0-9_-]+$", str)

function _split_production_string(
  production::String
)::Tuple{Vector{Symbol}, Vector{Symbol}, Vector{Symbol}}
  sanitized = strip(production)
  symbols = split(sanitized, r"\s+")
  terminals::Vector{Symbol} = []
  nonterminals::Vector{Symbol} = []
  for _symbol in symbols
    if islowercased(_symbol)
      push!(nonterminals, Symbol(_symbol))
    elseif isuppercased(_symbol)
      push!(terminals, Symbol(_symbol))
    else
      error("Symbol in production has to be either lowercase or uppercase (got $_symbol)")
    end
  end
  return (Symbol.(symbols), terminals, nonterminals)
end

# TODO: Better error signaling
function _read_definition_file(
  file::IOStream
)::Parser
  current_section = definitions
  current_production_lhs::Union{Symbol, Nothing} = nothing
  terminals::Set{Symbol} = Set()
  nonterminals::Set{Symbol} = Set()
  starting::Union{Symbol, Nothing} = nothing
  productions::Dict{Symbol, Production}  = Dict()
  symbol_types::Dict{Symbol, Symbol} = Dict()
  tokens::Set{Token} = Set()
  token_aliases::Dict{String, Token} = Dict()
  code_blocks::Vector{String} = []
  options = Options() # TODO: Fill if needed

  text::String = read(file, String)
  cursor::Int = 1

  while cursor <= length(text)
    did_match::Bool = false
    for (definition, pattern) in SpecialDefinitionPatterns
      matched = findnext(pattern, text, cursor)
      if matched !== nothing || matched.start != cursor
        continue
      end
      m = match(pattern, text[matched])

      if definition == section
        current_section = _next_section(current_section)
      elseif definition == code_block
        code_block_txt = text[matched]
        push!(code_blocks, strip(code_block_txt[4:end-2])) # Omit %{\n and %}
      elseif definition == option
        _section_guard(current_section, definitions, "Option $(text[matched]) outside of definitions section")
        # TODO: Fill if needed
      elseif definition == token
        _section_guard(current_section, definitions, "Token definition $(text[matched]) outside of definitions section")
        t = Token(Symbol(m[:name]), m[:alias])

        if t in tokens
          error("Token $(text[matched]) already defined")
        end
        push!(tokens, t)

        if t.alias !== nothing
          token_aliases[t.alias] = t
        end
      elseif defintion == type
        _section_guard(current_section, definitions, "Type definition $(text[matched]) outside of definitions section")
        symbol_types[Symbol(m[:symbol])] = Symbol(m[:type])
      elseif definition == start
        _section_guard(current_section, productions, "Start definition $(text[matched]) outside of productions section")
        if starting !== nothing
          error("Start symbol already defined")
        end
        starting = Symbol(m[:symbol])
      elseif definition == production
        _section_guard(current_section, productions, "Production $(text[matched]) outside of productions section")
        current_production_lhs = Symbol(m[:lhs])

        if current_production_lhs in productions
          error("Production $(text[matched]) already defined")
        end

        if !islowercased(current_production_lhs)
          error("Production LHS has to be lowercase, because it is a nonterminal (got $(m[:lhs]))")
        end

        _production, _terminals, _nonterminals = _split_production_string(m[:production])
        push!(_nonterminals, current_production_lhs)

        union!(terminals, _terminals)
        union!(nonterminals, _nonterminals)

        return_type = get(symbol_types, current_production_lhs, Symbol("String"))

        productions[current_production_lhs] = Production(
          current_production_lhs,
          _production,
          m[:action],
          return_type
        )
      elseif definition == production_alt
        _section_guard(current_section, productions, "Production alternative $(text[matched]) outside of productions section")

        _production, _terminals, _nonterminals = _split_production_string(m[:production])
        push!(_nonterminals, current_production_lhs)

        union!(terminals, _terminals)
        union!(nonterminals, _nonterminals)
get
        return_type = (symbol_types, current_production_lhs, Symbol("String"))

        productions[current_production_lhs] = Production(
          current_production_lhs,
          _production,
          m[:action],
          return_type
        )
      end

      cursor += length(matched)
      did_match = true
      break
    end
  end

  return Parser(
    terminals,
    nonterminals,
    starting,
    productions,
    tokens,
    token_aliases,
    code_blocks,
    options
  )
end
