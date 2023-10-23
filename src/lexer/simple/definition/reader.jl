using Parameters: @consts

@enum Section definitions actions code
@enum SpecialDefinition section code_block option regex_alias action comment

@consts begin
  SectionDelimiter::String = "%%"
  CodeBlockStart::String = "%{"
  CodeBlockEnd::String = "%}"

  SECTION_REGEX = r"%%"
  CODE_BLOCK_REGEX = r"%{((?s:.)*?)%}"
  OPTION_REGEX = r"%option ((?:\w+ ?)+)"
  REGEX_ALIAS_REGEX = r"(?<name>[A-Z0-9_-]+)\s+(?<pattern>.+)"
  ACTION_REGEX = r"(?<pattern>.+?)\s+{(?<body>(?s:.)+?)}"
  COMMENT_REGEX = r"#=[^\n]*=#\n?"

  SpecialDefinitionPatterns::Vector{Pair{SpecialDefinition, Regex}} = [
    section => SECTION_REGEX,
    code_block => CODE_BLOCK_REGEX,
    option => OPTION_REGEX,
    regex_alias => REGEX_ALIAS_REGEX,
    # action => r"(?<pattern>{[A-Z0-9_-]+}|\".+?\"|[^\s]+?)\s+{(?<body>(?s:.)+?)}",
    action => ACTION_REGEX,
    comment => COMMENT_REGEX
  ]
end

# Structure of a definition file:
#
# definitions/flags/regex aliases
# %%
# regexes
# %%
# user code
#
# Blocks enclosed with %{ and %} are copied to the output file (in the same order).

function read_definition_file(
  path::String
)::Lexer
  lexer::Union{Lexer, Nothing} = nothing
  open(path) do file
    lexer = _read_definition_file(file)
  end

  return lexer::Lexer
end

function _next_section(
  current::Section
)::Section
  if current == definitions
    return actions
  elseif current == actions
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

# TODO: Better error signaling
function _read_definition_file(
  file::IOStream
)::Lexer
  current_section = definitions
  aliases::Vector{RegexAlias} = []
  lexer_actions::Vector{Action} = []
  options = Options() # TODO: Fill if needed
  code_blocks::Vector{String} = []

  text::String = read(file, String)
  cursor::Int = 1
  while cursor <= length(text)
    did_match::Bool = false

    for (definition, pattern) in SpecialDefinitionPatterns
      matched = findnext(pattern, text, cursor)
      if matched === nothing || matched.start != cursor
        continue
      end

      if definition == section
        current_section = _next_section(current_section)
      elseif definition == code_block
        code_block_txt = text[matched]
        push!(code_blocks, strip(code_block_txt[4:end-2])) # Omit %{\n and %}
      elseif definition == option
        _section_guard(current_section, definitions, "Option $(text[matched]) outside of definitions section")
        # TODO: Fill options if needed
      elseif definition == regex_alias
        _section_guard(current_section, definitions, "Regex alias $(text[matched]) outside of definitions section")

        m = match(pattern, text[matched])
        push!(aliases, RegexAlias(
          Symbol(m[:name]),
          m[:pattern]
        ))
      elseif definition == action
        _section_guard(current_section, actions, "Action $(text[matched]) outside of actions section")

        m = match(pattern, text[matched])
          push!(lexer_actions, Action(
          m[:pattern],
          m[:body]
        ))
      end

      cursor += length(text[matched])
      did_match = true
      break
    end

    if current_section == code && !isempty(strip(text[cursor:end]))
      to_copy = text[cursor:end]
      # Remove comments
      for m in eachmatch(COMMENT_REGEX, to_copy)
        to_copy = replace(to_copy, m.match => "")
      end

      # Copy everything
      push!(code_blocks, strip(to_copy))
      break
    end

    if !did_match
      # Omit whitespace (only one line at a time)
      whitespace = findnext(r"[\r\t\f\v\n ]+", text, cursor)
      # @debug text[cursor:end]
      if whitespace !== nothing && whitespace.start == cursor
        cursor += length(text[whitespace])
      else
        error("Invalid characters in definition file, $(text[cursor]), at $cursor)")
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
