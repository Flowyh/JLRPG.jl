using Parameters: @consts

@enum Section definitions actions code
@enum SpecialDefinition section code_block option regex_alias action

@consts begin
  SectionDelimiter::String = "%%"
  CodeBlockStart::String = "%{"
  CodeBlockEnd::String = "%}"

  SpecialDefinitionPatterns::Vector{Pair{SpecialDefinition, Regex}} = [
    section => r"%%",
    code_block => r"%{((?s:.)*?)%}",
    option => r"%option ((?:\w+ ?)+)",
    regex_alias => r"(?<name>[A-Z0-9_-]+)\s+(?<pattern>.+)",
    # action => r"(?<pattern>{[A-Z0-9_-]+}|\".+?\"|[^\s]+?)\s+{(?<body>(?s:.)+?)}",
    action => r"(?<pattern>.+?)\s+{(?<body>(?s:.)+?)}"
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
  elseif current == code
    throw("Invalid definition file, too many sections")
  end
end

function _section_guard(
  current::Section,
  expected::Section,
  err_msg::String
)
  if current != expected
    throw(err_msg)
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
        push!(code_blocks, code_block_txt[4:end-2]) # Omit %{\n and %}
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
      # Copy everything
      push!(code_blocks, text[cursor:end])
      break
    end

    if !did_match
      # Omit whitespace (only one line at a time)
      whitespace = findnext(r"[\r\t\f\v ]*\n", text, cursor)
      if whitespace !== nothing && whitespace.start == cursor
        cursor += length(text[whitespace])
      else
        throw("Invalid characters in definition file, $(text[cursor]), $cursor")
      end
    end  
  end

  if current_section != code
    throw("Invalid definition file, not enough sections")
  end

  return Lexer(
    lexer_actions,
    aliases,
    code_blocks,
    options
  )
end
