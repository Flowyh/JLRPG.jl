using Parameters: @consts

@enum ParserSection definitions productions code
@enum ParserSpecialDefinition section code_block option token type start production production_alt comment

@consts begin
  ParserSectionDelimiter::String = "%%"
  ParserCodeBlockStart::String = "%{"
  ParserCodeBlockEnd::String = "%}"

  PARSER_SECTION_REGEX = r"%%"
  PARSER_CODE_BLOCK_REGEX = r"%{((?s:.)*?)%}"
  PARSER_KW_OPTION_REGEX = r"%option[ \t]+(?<name>\w+)=\"(?<value>\w+)\""
  PARSER_OPTION_REGEX = r"%option[ \t]+(?<value>\w+)"
  TOKEN_REGEX = r"%token[ \t]+(?<name>\w+)(?:[ \t]+\"(?<alias>[^\"]+)\")?"
  TYPE_REGEX = r"%type[ \t]+<(?<type>(?:\w|\{|\})+)>(?:[ \t]+(?<symbol>\w+))?"
  START_REGEX = r"%start[ \t]+(?<symbol>\w+)"
  PRODUCTION_REGEX = r"(?<lhs>\w+)\s+->\s+(?<production>[^{}\n]+?)\s+:{(?<action>(?s:.)*?)}:"
  EMPTY_CALLBACK_PRODUCTION_REGEX = r"(?<lhs>\w+)\s+->\s+(?<production>[^{}\n]+)"
  PRODUCTION_ALT_REGEX = r"\|\s+(?<production>[^{}\n]+)\s+:{(?<action>(?s:.)*?)}:"
  EMPTY_CALLBACK_PRODUCTION_ALT_REGEX = r"\|\s+(?<production>[^{}\n]+)"
  PARSER_COMMENT_REGEX = r"#=[^\n]*=#"

  DOUBLE_QUOTES_ALIAS = r"\"(?<alias>[^\"]+)\""

  SpecialDefinitionPatterns::Vector{Pair{ParserSpecialDefinition, Regex}} = [
    section => PARSER_SECTION_REGEX,
    option => PARSER_KW_OPTION_REGEX,
    option => PARSER_OPTION_REGEX,
    token => TOKEN_REGEX,
    type => TYPE_REGEX,
    start => START_REGEX,
    production => PRODUCTION_REGEX,
    production => EMPTY_CALLBACK_PRODUCTION_REGEX,
    production_alt => PRODUCTION_ALT_REGEX,
    production_alt => EMPTY_CALLBACK_PRODUCTION_ALT_REGEX,
    code_block => PARSER_CODE_BLOCK_REGEX,
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
# TODO: Comment
"""
    read_parser_definition_file(path::String)::Parser

Read parser definition file and construct a `Parser` object.

The syntax for parser definition files follow the same syntax as
[GNU Bison](https://www.gnu.org/software/bison/) definition files.

# Definition file structure
Parser definition file consists of three sections:
  - Definitions section, where lexer tokens, types and parser options are defined.
  - Productions section, where grammar productions are defined.
  - Code section, where user code is defined.

Each section is separated by a `%%` delimiter.

# Definitions section
Definitions section consists of lexer tokens, types and parser options.

## Lexer tokens
Each lexer token that might be passed to parser during the parsing process must be
defined in this section. To define a lexer token, use the following syntax:
```
%token NAME "ALIAS"
```
where `NAME` is the uppercased name of the token and `ALIAS` is a optional string
literal, which may be used to refer to the token in the parser productions section.

## Types
Each nonterminal symbol may be assigned a type. To assign a type to a nonterminal,
use the following syntax:
```
%type <type> symbol
```
where `type` is the type of the symbol and `symbol` is the lowercase name of the symbol.
The type may be any valid Julia type, including user-defined types.

If a type is not assigned to a nonterminal, it is assumed to be `Nothing`.

If a type is assigned to a nonterminal, it is assumed that the user will return a value
of that type from the action associated with the production. To return a value from the
action, assign it to the `\$\$` variable.

## Parser options
Parser options may be used to configure the parser. Currently, the following options are
available:
  - `tag`: Rename the prefix of all objects generated in the parser. This includes all
    token definitions, special functions, etc.
  - `lexer_tag`: Rename the prefix of all objects associated with the lexer that are used
    in the parser. This includes all token definitions, special functions, etc.
  - `parser_type`: Specify the type of the parser. Currently, the following types are
    available:
      - `SLR`
      - `LR`
      - `LALR`

Parser options are defined as follows:
```
%option tag="TAG_NAME"
%option lexer_tag="LEXER_TAG_NAME"
%option SLR
%option LR
%option LALR
```
where `TAG_NAME` is the new parser prefix, `LEXER_TAG_NAME` is the new prefix for lexer
objects.

Renaming the parser tag will also rename the default name of the generated parser file.
For example if the tag is set to `MyParser`, the generated parser file will be named
`MyParser.jl`.

# Productions section
Productions section consists of grammar productions. Each production is defined as follows:
```
lhs -> production :{ action }:
```
where `lhs` is the left-hand side of the production, `production` is the right-hand side.
Right-hand side might consist of terminals (uppercased symbols), nonterminals (lowercased
symbols) or an `%empty` keyword, which represents an empty production. `%empty` should not
be mixed with other symbols in a single production.

The `action` is an optional Julia code block, which is executed when the production is
reduced. The `action` may return a value, which will be assigned to the left-hand side of
the production. To return a value from the action, assign it to the `\$\$` variable:
```
lhs -> production :{ \$\$ = value }:
```

If a given left-hand side has multiple productions, they have to be defined below the first
production using the following syntax:
```
lhs -> production :{ action }:
     | alt_production :{ action }:
```

To refer to the values of symbols in the right-hand side of the production, use the
`\$<number>` syntax, for example:
```
lhs -> production :{ \$\$ = \$1 + \$3 }:
```
where `\$n` refers to the nth symbol in the right-hand side of the production.

The first production of the first nonterminal is considered as the starting production,
unless a special flag is specified. Use `%start` flag to specify the starting production:
```
%start lhs
```
where `lhs` is the left-hand side of the starting production.

# Code section
Code section consists of user code. It is copied to the output file as is, in the same
order as it was defined in the definition file.

Additionally the user may define code blocks enclosed with `%{` and `%}`,
which will be also copied to the output file.
Code blocks may be inserted in all of the sections, but they should not be intermixed
with other definition file constructs (such as production definitions, flags, etc.).

# Commenting
Comments are defined using the `#=` and `=#` delimiters. Comments are single-line only.
They should not be mixed with other definition file constructs.

# Examples
For valid parser definition files examples see the `examples` directory.
"""
function read_parser_definition_file(
  path::String
)::Parser
  parser::Union{Nothing, Parser} = nothing
  open(path) do file
    text::String = read(file, String)
    c::Cursor = Cursor(text; source=path)
    parser = _read_parser_definition_file(c)
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
  c::Cursor,
  err_msg::String;
  erroneous_slice::Union{Nothing, UnitRange{Int}} = nothing
)
  if current != expected
    cursor_error(c, err_msg; erroneous_slice=erroneous_slice)
  end
end

islowercased(str::AbstractString)::Bool = occursin(r"^[a-z0-9_-]+$", str)
isuppercased(str::AbstractString)::Bool = occursin(r"^[A-Z0-9_-]+$", str)

function _split_production_string(
  production_lhs::Symbol,
  production::AbstractString,
  lexer_token_aliases::Dict{Symbol, Symbol},
  c::Cursor,
  erroneous_slice::Union{Nothing, UnitRange{Int}} = nothing
)::Tuple{Vector{Symbol}, Vector{Symbol}, Vector{Symbol}}
  sanitized = strip(production)
  symbols = split(sanitized, r"\s+")

  if length(symbols) == 1 && symbols[1] == "%empty"
    return (EMPTY_PRODUCTION, [], [])
  elseif length(symbols) != 1 && "%empty" in symbols
    cursor_error(
      c, "%empty productions cannot be mixed with other symbols";
      erroneous_slice=erroneous_slice
    )
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
      if !haskey(lexer_token_aliases, Symbol(_symbol))
        cursor_error(
          c, "Token alias not defined";
          erroneous_slice=erroneous_slice
        )
      end
      is_alias = true
    end

    token = Symbol(_symbol)
    if is_alias
      token = lexer_token_aliases[Symbol(_symbol)] # Get normal token instead of alias
      push!(terminals, token)
    elseif isuppercased(_symbol)
      push!(terminals, token)
    elseif islowercased(_symbol)
      push!(nonterminals, token)
    else
      cursor_error(
        c, "Symbol in production has to be either lowercase or uppercase (got $_symbol)";
        erroneous_slice=erroneous_slice
      )
    end
    push!(production, token)
  end
  return (production, terminals, nonterminals)
end

function _read_parser_definition_file(
  c::Cursor
)::Parser
  current_section = definitions
  current_production_lhs::Union{Nothing, Symbol} = nothing
  terminals::Vector{Symbol} = []
  nonterminals::Vector{Symbol} = []
  starting::Union{Nothing, Symbol} = nothing
  parser_productions::Dict{Symbol, Vector{ParserProduction}}  = Dict()
  symbol_types::Dict{Symbol, Symbol} = Dict()
  lexer_tokens::Set{Symbol} = Set()
  lexer_token_aliases::Dict{Symbol, Symbol} = Dict()
  code_blocks::Vector{String} = []
  options = Dict() # TODO: Fill if needed

  while !cursor_is_eof(c)
    did_match::Bool = false

    for (definition, pattern) in SpecialDefinitionPatterns
      matched = cursor_findnext_and_move(c, pattern)
      if matched === nothing
        continue
      end
      m = cursor_match(c, pattern; slice=matched)

      if definition == section
        current_section = _next_parser_section(current_section)
      elseif definition == code_block
        code_block_txt = cursor_slice(c, matched)
        push!(code_blocks, strip(code_block_txt[4:end-2])) # Omit %{\n and %}
      elseif definition == option
        _parser_section_guard(
          current_section,
          definitions,
          c, "Option outside of definitions section";
          erroneous_slice=matched
        )
        if haskey(m, :name) # KW option
          if m[:name] == "tag"
            options[:tag] = m[:value]
          elseif m[:name] == "lexer_tag"
            options[:lexer_tag] = m[:value]
          end
        else
          if m[:value] in ["SLR", "LR", "LALR"]
            options[:parser_type] = ParserTypeFromSymbol[Symbol(m[:value])]
          end
        end
      elseif definition == token
        _parser_section_guard(
          current_section,
          definitions,
          c, "Token definition outside of definitions section";
          erroneous_slice=matched
        )

        if !isuppercased(m[:name])
          cursor_error(
            c, "Token name must be uppercase";
            erroneous_slice=matched
          )
        end

        t, a = Symbol(m[:name]), Symbol(m[:alias])

        if t in lexer_tokens || a in lexer_tokens
          cursor_error(
            c, "Token already defined";
            erroneous_slice=matched
          )
        end
        push!(lexer_tokens, t)
        push!(terminals, t)

        if m[:alias] !== nothing
          push!(lexer_tokens, a)
          lexer_token_aliases[a] = t
          lexer_token_aliases[t] = a
        end
      elseif definition == type
        _parser_section_guard(
          current_section,
          definitions,
          c, "Type definition outside of definitions section";
          erroneous_slice=matched
        )

        if !islowercased(m[:symbol])
          cursor_error(
            c, "Typed symbol must be either lowercase (nonterminal)";
            erroneous_slice=matched
          )
        end

        s, t = Symbol(m[:symbol]), Symbol(m[:type])

        if haskey(symbol_types, s)
          cursor_error(
            c, "Type already defined";
            erroneous_slice=matched
          )
        end

        symbol_types[s] = Symbol(t)
      elseif definition == start
        _parser_section_guard(
          current_section,
          productions,
          c, "Start definition outside of productions section";
          erroneous_slice=matched
        )
        if starting !== nothing
          cursor_error(
            c, "Start symbol already defined";
            erroneous_slice=matched
          )
        end

        if !islowercased(m[:symbol])
          cursor_error(
            c, "Start symbol must be lowercase";
            erroneous_slice=matched
          )
        end

        starting = Symbol(m[:symbol])
      elseif definition == production || definition == production_alt
        _parser_section_guard(
          current_section,
          productions,
          c, "Production outside of productions section";
          erroneous_slice=matched
        )

        if definition == production
          if !islowercased(m[:lhs])
            cursor_error(
              c, "Production left-hand side must be lowercase";
              erroneous_slice=matched
            )
          end

          current_production_lhs = Symbol(m[:lhs])

          if haskey(parser_productions, current_production_lhs)
            cursor_error(
              c, "Production left-hand side repeated";
              erroneous_slice=matched
            )
          end

          # First production is considered as the starting production, unless specified otherwise
          if starting === nothing
            starting = current_production_lhs
          end
        end

        _production, _terminals, _nonterminals = _split_production_string(
          current_production_lhs,
          m[:production],
          lexer_token_aliases,
          c, matched
        )

        union!(terminals, _terminals)
        union!(nonterminals, _nonterminals)

        return_type = get(symbol_types, current_production_lhs, :Nothing)

        if !haskey(parser_productions, current_production_lhs)
          parser_productions[current_production_lhs] = []
        end

        push!(parser_productions[current_production_lhs], ParserProduction(
          current_production_lhs,
          _production,
          haskey(m, :action) ? strip(m[:action]) : nothing,
          return_type
        ))
      end

      did_match = true
      break
    end

    if current_section == code && !isempty(strip(cursor_rest(c)))
      to_copy = cursor_rest(c)
      # Remove comments
      for m in eachmatch(PARSER_COMMENT_REGEX, to_copy)
        to_copy = replace(to_copy, m.match => "")
      end

      # Copy everything
      push!(code_blocks, strip(to_copy))
      break
    end

    # Omit whitespace
    whitespace = cursor_findnext_and_move(c, r"[\r\t\f\v\n ]+")
    if whitespace !== nothing
      did_match = true
    end

    if !did_match
      cursor_error(c, "Invalid character/s in definition file")
    end
  end

  # Add return types to symbols which did not have one specified by %type <Type> Symbol
  # nothing by default
  for symbol in nonterminals
    if !haskey(symbol_types, symbol)
      symbol_types[symbol] = :Nothing
    end
  end

  if current_section != code
    error("Invalid definition file, not enough sections")
  end

  if starting === nothing
    error("No start symbol detected")
  end

  if !(starting in nonterminals)
    error("Start symbol not a valid nonterminal")
  end

  return Parser(
    terminals,
    nonterminals,
    starting::Symbol,
    parser_productions,
    symbol_types,
    lexer_tokens,
    lexer_token_aliases,
    code_blocks,
    ParserOptions(options)
  )
end

#============#
# PRECOMPILE #
#============#
precompile(read_parser_definition_file, (
  String,
))
precompile(_next_parser_section, (
  ParserSection,
))
precompile(_parser_section_guard, (
  ParserSection,
  ParserSection,
  Cursor,
  String,
  Union{Nothing, UnitRange{Int}}
))
precompile(islowercased, (
  AbstractString,
))
precompile(isuppercased, (
  AbstractString,
))
precompile(_split_production_string, (
  Symbol,
  AbstractString,
  Dict{Symbol, Symbol},
  Cursor,
  Union{Nothing, UnitRange{Int}}
))
precompile(_read_parser_definition_file, (
  Cursor,
))
