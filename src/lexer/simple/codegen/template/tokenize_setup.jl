function __LEX__tokenize(txt::String)::Vector{LexerToken}
  @debug "<<<<<: START OF TOKENIZE :>>>>>"
  tokens::Vector{LexerToken} = []
  cursor::Int = 1
  while cursor <= length(txt)
    did_match::Bool = false
    for pattern in ACTION_PATTERNS
      matched = findnext(pattern, txt, cursor)
      if matched === nothing || matched.start != cursor
        continue
      end
      @debug "New match of length $(length(matched)) found: $(txt[matched])"
      __LEX__current_match(txt[matched])

      token = PATTERN_TO_ACTION[pattern]()
      if token isa LexerToken
        @debug "New token has been created: $token"
        push!(tokens, token)
      end

      did_match = true
      cursor += length(matched)
      break
    end

    if !did_match
      error("Syntax error, cannot match remaining text: $(txt[cursor:end])")
    end
  end

  @debug "<<<<<:   END OF TOKENIZE :>>>>>"
  return tokens
end