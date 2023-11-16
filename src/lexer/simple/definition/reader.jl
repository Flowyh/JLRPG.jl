using Parameters: @consts

@enum LexerSection definitions actions code
@enum LexerSpecialDefinition section code_block option regex_alias action comment

@consts begin
  LexerSectionDelimiter::String = "%%"
  LexerCodeBlockStart::String = "%{"
  LexerCodeBlockEnd::String = "%}"

  LEXER_SECTION_REGEX = r"%%"
  LEXER_CODE_BLOCK_REGEX = r"%{((?s:.)*?)%}"
  LEXER_OPTION_REGEX = r"%option[ \t]+((?:\w+ ?)+)"
  REGEX_ALIAS_REGEX = r"(?<name>[A-Z0-9_-]+)\s+(?<pattern>.+)"
  ACTION_REGEX = r"(?<pattern>.+?)\s+{(?<body>(?s:.)+?)}"
  LEXER_COMMENT_REGEX = r"#=[^\n]*=#\n?"

  SpecialDefinitionPatterns::Vector{Pair{LexerSpecialDefinition, Regex}} = [
    section => LEXER_SECTION_REGEX,
    code_block => LEXER_CODE_BLOCK_REGEX,
    comment => LEXER_COMMENT_REGEX,
    regex_alias => REGEX_ALIAS_REGEX,
    option => LEXER_OPTION_REGEX,
    action => ACTION_REGEX
  ]
end

# Structure of a definition file:
#
# definitions/flags/regex aliases
# %%
# lexer actions
# %%
# user code
#
# Blocks enclosed with %{ and %} are copied to the output file (in the same order).

function read_lexer_definition_file(
  path::String
)::Lexer
  lexer::Union{Nothing, Lexer} = nothing
  open(path) do file
    text::String = read(file, String)
    c::Cursor = Cursor(text; source=path)
    lexer = _read_lexer_definition_file(c)
  end

  return lexer::Lexer
end

function _next_lexer_section(
  current::LexerSection
)::LexerSection
  if current == definitions
    return actions
  elseif current == actions
    return code
  end
end

function _lexer_section_guard(
  current::LexerSection,
  expected::LexerSection,
  c::Cursor,
  err_msg::String;
  erroneous_slice::Union{Nothing, UnitRange{Int}} = nothing
)
  if current != expected
    cursor_error(c, err_msg; erroneous_slice=erroneous_slice)
  end
end

# TODO: Better error signaling
function _read_lexer_definition_file(
  c::Cursor
)::Lexer
  current_section = definitions
  aliases::Vector{RegexAlias} = []
  lexer_actions::Vector{LexerAction} = []
  options = LexerOptions() # TODO: Fill if needed
  code_blocks::Vector{String} = []

  while !cursor_is_eof(c)
    did_match::Bool = false

    for (definition, pattern) in SpecialDefinitionPatterns
      matched = cursor_findnext_and_move(c, pattern)
      if matched === nothing
        continue
      end
      m = cursor_match(c, pattern; slice=matched)

      if definition == section
        current_section = _next_lexer_section(current_section)
      elseif definition == code_block
        code_block_txt = cursor_slice(c, matched)
        push!(code_blocks, strip(code_block_txt[4:end-2])) # Omit %{\n and %}
      elseif definition == option
        _lexer_section_guard(
          current_section,
          definitions,
          c, "Option $(cursor_slice(c, matched)) outside of definitions section";
          erroneous_slice=matched
        )
        # TODO: Fill options if needed
      elseif definition == regex_alias
        _lexer_section_guard(
          current_section,
          definitions,
          c, "Regex alias $(cursor_slice(c, matched)) outside of definitions section";
          erroneous_slice=matched
        )
        push!(aliases, RegexAlias(
          Symbol(m[:name]),
          m[:pattern]
        ))
      elseif definition == action
        _lexer_section_guard(
          current_section,
          actions,
          c, "Action $(cursor_slice(c, matched)) outside of actions section";
          erroneous_slice=matched
        )
        push!(lexer_actions, LexerAction(
          m[:pattern],
          m[:body]
        ))
      end

      did_match = true
      break
    end

    if current_section == code && !isempty(strip(cursor_rest(c)))
      to_copy = cursor_rest(c)
      # Remove comments
      for m in eachmatch(LEXER_COMMENT_REGEX, to_copy)
        to_copy = replace(to_copy, m.match => "")
      end

      # Copy everything
      push!(code_blocks, strip(to_copy))
      break
    end

    if !did_match
      # Omit whitespace
      whitespace = cursor_findnext_and_move(c, r"[\r\t\f\v\n ]+")
      if whitespace === nothing
        cursor_error(c, "Invalid character/s in definition file")
      end
    end
  end

  if current_section != code
    error("Invalid definition file, not enough sections")
  end

  return Lexer(
    lexer_actions,
    aliases,
    code_blocks,
    options
  )
end
