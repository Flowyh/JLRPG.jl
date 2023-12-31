using Parameters: @consts

"Possible parts of a pattern in a lexer action."
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

"""
    expand_regex_aliases_in_aliases(aliases::Vector{RegexAlias})::Vector{RegexAlias}

Expand lexer regex `aliases` inside the patterns of other `aliases`.

Aliases have to be defined before they are referenced.
"""
function expand_regex_aliases_in_aliases(aliases::Vector{RegexAlias})::Vector{RegexAlias}
  # Aliases are expanded in-place of {ALIAS_NAME} in the patterns
  expanded_aliases::Vector{RegexAlias} = []
  defined_aliases::Set{Symbol} = Set()
  visited_aliases::Dict{Symbol, String} = Dict()

  for alias in aliases
    name, pattern = alias.name, alias.pattern
    alias_matches = findall(ALIAS_PATTERN, pattern)
    replacements = []
    if !isempty(alias_matches)
      for alias_match in alias_matches
        m = match(ALIAS_PATTERN, pattern[alias_match])
        alias_name = Symbol(m[:name])
        # Alias referenced before it was defined
        if !haskey(visited_aliases, alias_name)
          error("Invalid definition file, alias for $(alias_name) was referenced before it was defined")
        end
        push!(replacements, pattern[alias_match] => visited_aliases[alias_name])
      end
      pattern = replace(pattern, replacements...)
    end

    if name in defined_aliases
      error("Invalid definition file, alias $(name) has already been defined")
    end
    push!(defined_aliases, name)
    push!(expanded_aliases, RegexAlias(name, pattern))
    push!(visited_aliases, name => pattern)
  end

  return expanded_aliases
end

"""
    expand_regex_aliases_in_actions(
      actions::Vector{LexerAction},
      expanded_aliases::Vector{RegexAlias}
    )::Vector{LexerAction}

Expand lexer regex `aliases` inside of the patterns of `actions`.

Aliases provided as `expanded_aliases` should contain previously expanded aliases. Literal strings enclosed in double quotes are escaped using `\\Q` and `\\E` sequences.
"""
function expand_regex_aliases_in_actions(
  actions::Vector{LexerAction},
  expanded_aliases::Vector{RegexAlias}
)::Vector{LexerAction}
  # Aliases have to be expanded beforehand, because they may contain other aliases
  visited_aliases::Dict{Symbol, String} = Dict(
    alias.name => alias.pattern for alias in expanded_aliases
  )

  # Expand action patterns into proper regexes
  # Go through the pattern, split it into parts, and expand the aliases in each part
  expanded_actions::Vector{LexerAction} = []
  defined_patterns::Set{String} = Set()
  for action in actions
    pattern, body = action.pattern, action.body
    new_pattern::String = ""
    c::Cursor = Cursor(pattern)

    while !cursor_is_eof(c)
      for (part_type, part_pattern) in PatternParts
        matched = cursor_findnext_and_move(c, part_pattern)
        if matched === nothing
          continue
        end
        m = cursor_match(c, part_pattern; slice=matched)

        if part_type == alias
          alias_name = Symbol(m[:name])
          if !haskey(visited_aliases, alias_name)
            error("Invalid definition file, alias for $(alias_name) is not defined")
          end
          new_pattern *= visited_aliases[alias_name]
        elseif part_type == string
          new_pattern *= "\\Q$(m[:pattern])\\E"
        else
          new_pattern *= m[:pattern]
        end

        break
      end
    end

    push!(defined_patterns, new_pattern)
    push!(expanded_actions, LexerAction(new_pattern, body))
  end

  return expanded_actions
end


"""
    expand_regex_aliases_in_lexer(lexer::Lexer)::Lexer

Expand aliases and actions in `lexer` into proper regexes.
"""
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

#============#
# PRECOMPILE #
#============#
precompile(expand_regex_aliases_in_lexer, (
  Lexer,
))
precompile(expand_regex_aliases_in_actions, (
  Vector{LexerAction},
  Vector{RegexAlias}
))
precompile(expand_regex_aliases_in_aliases, (
  Vector{RegexAlias},
))
