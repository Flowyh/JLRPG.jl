using Parameters: @consts

@enum PatternPart alias string regex

@consts begin
  ALIAS_PATTERN::Regex = r"{(?<name>[A-Z0-9_-]+)}"
  ANYTHING_PATTERN::Regex = r"(?<pattern>.+?)"
  RAW_STRING_PATTERN::Regex = r"\"(?<pattern>.+?)\""
  PatternParts::Vector{Pair{PatternPart, Regex}} = [
    alias => ALIAS_PATTERN,
    string => RAW_STRING_PATTERN,
    regex => ANYTHING_PATTERN
  ]
end

function expand_regex_aliases_in_aliases(aliases::Vector{RegexAlias})::Vector{RegexAlias}
  # Aliases are expanded in-place of {ALIAS_NAME} in the patterns
  expanded_aliases::Vector{RegexAlias} = []
  visited_aliases::Dict{Symbol, String} = Dict()

  # Order of aliases is important, so for each analyzed alias we will mark it as visited
  for alias in aliases
    name, pattern = alias.name, alias.pattern
    alias_matches = findall(ALIAS_PATTERN, pattern)
    if !isempty(alias_matches)
      for alias_match in alias_matches
        m = match(ALIAS_PATTERN, pattern[alias_match])
        alias_name = Symbol(m[:name])
        if !haskey(visited_aliases, alias_name) # Alias referenced before it was defined
          throw("Invalid definition file, alias for $(alias_name) was referenced before it was defined")
        end
        pattern = replace(pattern, pattern[alias_match] => visited_aliases[alias_name])
      end
    end
    push!(expanded_aliases, RegexAlias(name, pattern))
    push!(visited_aliases, name => pattern)
  end

  return expanded_aliases
end

function expand_regex_aliases_in_actions(
  actions::Vector{Action},
  expanded_aliases::Vector{RegexAlias}
)::Vector{Action}
  # Aliases have to be expanded beforehand, because they may contain other aliases
  visited_aliases::Dict{Symbol, String} = Dict(
    alias.name => alias.pattern for alias in expanded_aliases
  )

  # Expand action patterns into proper regexes
  # Go through the pattern, split it into parts, and expand the aliases in each part
  expanded_actions::Vector{Action} = []
  defined_patterns::Set{String} = Set()
  for action in actions
    pattern, body = action.pattern, action.body
    new_pattern::String = ""
    cursor::Int = 1
    while cursor <= length(pattern)
      did_match::Bool = false
      for (part_type, part_pattern) in PatternParts
        matched = findnext(part_pattern, pattern, cursor)
        if matched === nothing || matched.start != cursor
          continue
        end
        m = match(part_pattern, pattern[matched])
        if part_type == alias
          alias_name = Symbol(m[:name])
          if !haskey(visited_aliases, alias_name)
            throw("Invalid definition file, alias for $(alias_name) is not defined")
          end
          new_pattern *= visited_aliases[alias_name]
        else
          new_pattern *= m[:pattern]
        end

        cursor += length(matched)
        did_match = true
        break
      end

      if !did_match
        throw("Invalid definition file, invalid pattern $(pattern[cursor])")
      end
    end

    if new_pattern in defined_patterns
      throw("Invalid definition file, pattern $(new_pattern) has already been defined")
    end
    push!(defined_patterns, new_pattern)
    push!(expanded_actions, Action(new_pattern, body))
  end

  return expanded_actions
end

function expand_regex_aliases_in_lexer(lexer::Lexer)::Lexer
  expanded_aliases = expand_regex_aliases_in_aliases(lexer.aliases)
  expanded_actions = expand_regex_aliases_in_actions(lexer.actions, expanded_aliases)

  return Lexer(
    expanded_actions,
    expanded_aliases,
    lexer.code_blocks,
    lexer.options
  )
end
