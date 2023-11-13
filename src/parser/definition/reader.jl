using Parameters: @consts

@enum ParserSection definitions productions code
@enum ParserSpecialDefinition section code_block option token type start production production_alt comment

@consts begin
  ParserSectionDelimiter::String = "%%"
  ParserCodeBlockStart::String = "%{"
  ParserCodeBlockEnd::String = "%}"

  PARSER_SECTION_REGEX = r"%%"
  PARSER_CODE_BLOCK_REGEX = r"%{((?s:.)*?)%}"
  PARSER_OPTION_REGEX = r"%option[ \t]+((?:\w+ ?)+)"
  TOKEN_REGEX = r"%token[ \t]+(?<name>\w+)(?:[ \t]+\"(?<alias>[^\"]+)\")?"
  TYPE_REGEX = r"%type[ \t]+<(?<type>\w+)>(?:[ \t]+(?<symbol>\w+))?"
  START_REGEX = r"%start[ \t]+(?<symbol>\w+)"
  PRODUCTION_REGEX = r"(?<lhs>\w+)\s+->\s+(?<production>[^{}\n]+?)\s+{(?<action>(?s:.)*?)}"
  EMPTY_CALLBACK_PRODUCTION_REGEX = r"(?<lhs>\w+)\s+->\s+(?<production>[^{}\n]+)"
  PRODUCTION_ALT_REGEX = r"\|\s+(?<production>[^{}\n]+)\s+{(?<action>(?s:.)*?)}"
  EMPTY_CALLBACK_PRODUCTION_ALT_REGEX = r"\|\s+(?<production>[^{}\n]+)"
  PARSER_COMMENT_REGEX = r"#=[^\n]*=#\n?"

  DOUBLE_QUOTES_ALIAS = r"\"(?<alias>[^\"]+)\""

  SpecialDefinitionPatterns::Vector{Pair{ParserSpecialDefinition, Regex}} = [
    section => PARSER_SECTION_REGEX,
    code_block => PARSER_CODE_BLOCK_REGEX,
    option => PARSER_OPTION_REGEX,
    token => TOKEN_REGEX,
    type => TYPE_REGEX,
    start => START_REGEX,
    production => PRODUCTION_REGEX,
    production => EMPTY_CALLBACK_PRODUCTION_REGEX,
    production_alt => PRODUCTION_ALT_REGEX,
    production_alt => EMPTY_CALLBACK_PRODUCTION_ALT_REGEX,
    comment => PARSER_COMMENT_REGEX
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

function read_parser_definition_file(
  path::String
)::Parser
  parser::Union{Parser, Nothing} = nothing
  open(path) do file
    parser = _read_parser_definition_file(file)
  end

  return parser::Parser
end

function _next_parser_section(
  current::ParserSection
)::ParserSection
  if current == definitions
    return productions
  elseif current == productions
    return code
  end
end

function _parser_section_guard(
  current::ParserSection,
  expected::ParserSection,
  err_msg::String
)
  if current != expected
    error(err_msg)
  end
end

islowercased(str::AbstractString)::Bool = occursin(r"^[a-z0-9_-]+$", str)
isuppercased(str::AbstractString)::Bool = occursin(r"^[A-Z0-9_-]+$", str)

function _split_production_string(
  production_lhs::Symbol,
  production::AbstractString,
  token_aliases::Dict{Symbol, Symbol}
)::Tuple{Vector{Symbol}, Vector{Symbol}, Vector{Symbol}}
  sanitized = strip(production)
  symbols = split(sanitized, r"\s+")

  if length(symbols) == 1 && symbols[1] == "%empty"
    return (EMPTY_PRODUCTION, [], [])
  elseif length(symbols) != 1 && "%empty" in symbols
    error("Production $production_lhs -> $production contains %empty and other symbols")
  end

  production::Vector{Symbol} = []
  terminals::Vector{Symbol} = []
  nonterminals::Vector{Symbol} = [production_lhs]
  for _symbol in symbols
    # If is an alias
    is_alias::Bool = false
    m = match(DOUBLE_QUOTES_ALIAS, _symbol)
    if m !== nothing
      _symbol = m[:alias]
      if !haskey(token_aliases, Symbol(_symbol))
        error("Token alias $_symbol not defined")
      end
      is_alias = true
    end

    token = Symbol(_symbol)
    if is_alias
      token = token_aliases[Symbol(_symbol)] # Get normal token instead of alias
      push!(terminals, token)
    elseif isuppercased(_symbol)
      push!(terminals, token)
    elseif islowercased(_symbol)
      push!(nonterminals, token)
    else
      error("Symbol in production has to be either lowercase or uppercase (got $_symbol)")
    end
    push!(production, token)
  end
  return (production, terminals, nonterminals)
end

# TODO: Better error signaling
function _read_parser_definition_file(
  file::IOStream
)::Parser
  current_section = definitions
  current_production_lhs::Union{Symbol, Nothing} = nothing
  terminals::Vector{Symbol} = []
  nonterminals::Vector{Symbol} = []
  starting::Union{Symbol, Nothing} = nothing
  parser_productions::Dict{Symbol, Vector{ParserProduction}}  = Dict()
  symbol_types::Dict{Symbol, Symbol} = Dict()
  tokens::Set{Symbol} = Set()
  token_aliases::Dict{Symbol, Symbol} = Dict()
  code_blocks::Vector{String} = []
  options = ParserOptions() # TODO: Fill if needed

  text::String = read(file, String)
  cursor::Int = 1

  while cursor <= length(text)
    did_match::Bool = false
    for (definition, pattern) in SpecialDefinitionPatterns
      matched = findnext(pattern, text, cursor)
      if matched === nothing || matched.start != cursor
        continue
      end
      m = match(pattern, text[matched])

      if definition == section
        current_section = _next_parser_section(current_section)
      elseif definition == code_block
        code_block_txt = text[matched]
        push!(code_blocks, strip(code_block_txt[4:end-2])) # Omit %{\n and %}
      elseif definition == option
        _parser_section_guard(current_section, definitions, "Option $(text[matched]) outside of definitions section")
        # TODO: Fill if needed
      elseif definition == token
        _parser_section_guard(current_section, definitions, "Token definition $(text[matched]) outside of definitions section")

        if !isuppercased(m[:name])
          error("Token $(text[matched]) name must be uppercase")
        end

        t, a = Symbol(m[:name]), Symbol(m[:alias])

        if t in tokens || a in tokens
          error("Token $(text[matched]) already defined")
        end
        push!(tokens, t)
        push!(terminals, t)

        if m[:alias] !== nothing
          push!(tokens, a)
          token_aliases[a] = t
          token_aliases[t] = a
        end
      elseif definition == type
        _parser_section_guard(current_section, definitions, "Type definition $(text[matched]) outside of definitions section")
        symbol_types[Symbol(m[:symbol])] = Symbol(m[:type])
      elseif definition == start
        _parser_section_guard(current_section, productions, "Start definition $(text[matched]) outside of productions section")
        if starting !== nothing
          error("Start symbol already defined")
        end
        starting = Symbol(m[:symbol])
      elseif definition == production
        _parser_section_guard(current_section, productions, "Production $(text[matched]) outside of productions section")

        if !islowercased(m[:lhs])
          error("Production $(text[matched]) left-hand side must be lowercase")
        end

        current_production_lhs = Symbol(m[:lhs])

        if haskey(parser_productions, current_production_lhs)
          error("Production left-hand side $current_production_lhs repeated")
        end

        # First production is considered as the starting production, unless specified otherwise
        if starting === nothing
          starting = current_production_lhs
        end

        _production, _terminals, _nonterminals = _split_production_string(
          current_production_lhs,
          m[:production],
          token_aliases
        )

        union!(terminals, _terminals)
        union!(nonterminals, _nonterminals)

        return_type = get(symbol_types, current_production_lhs, :nothing)

        if !haskey(parser_productions, current_production_lhs)
          parser_productions[current_production_lhs] = []
        end

        push!(parser_productions[current_production_lhs], ParserProduction(
          current_production_lhs,
          _production,
          haskey(m, :action) ? m[:action] : nothing, # TODO: utils get for regexmatches
          return_type
        ))
      elseif definition == production_alt
        _parser_section_guard(current_section, productions, "Production alternative $(text[matched]) outside of productions section")

        _production, _terminals, _nonterminals = _split_production_string(
          current_production_lhs,
          m[:production],
          token_aliases
        )

        union!(terminals, _terminals)
        union!(nonterminals, _nonterminals)

        return_type = get(symbol_types, current_production_lhs, :nothing)

        if !haskey(parser_productions, current_production_lhs)
          parser_productions[current_production_lhs] = []
        end

        push!(parser_productions[current_production_lhs], ParserProduction(
          current_production_lhs,
          _production,
          haskey(m, :action) ? m[:action] : nothing,
          return_type
        ))
      end

      cursor += length(matched)
      did_match = true
      break
    end

    if current_section == code && !isempty(strip(text[cursor:end]))
      to_copy = text[cursor:end]
      # Remove comments
      for m in eachmatch(PARSER_COMMENT_REGEX, to_copy)
        to_copy = replace(to_copy, m.match => "")
      end

      # Copy everything
      push!(code_blocks, strip(to_copy))
      break
    end

    if !did_match
      # Omit whitespace (only one line at a time)
      whitespace = findnext(r"[\r\t\f\v\n ]+", text, cursor)
      if whitespace !== nothing && whitespace.start == cursor
        cursor += length(text[whitespace])
      else
        error("Invalid characters in definition file, $(text[cursor]), at $cursor")
      end
    end
  end

  # Add return types to symbols which did not have one specified by %type <Type> Symbol
  # nothing by default
  for symbol in nonterminals
    if !haskey(symbol_types, symbol)
      symbol_types[symbol] = :nothing
    end
  end

  if current_section != code
    error("Invalid definition file, not enough sections")
  end

  if starting === nothing
    error("No start symbol detected")
  end

  return Parser(
    terminals,
    nonterminals,
    starting::Symbol,
    parser_productions,
    symbol_types,
    tokens,
    token_aliases,
    code_blocks,
    options
  )
end
