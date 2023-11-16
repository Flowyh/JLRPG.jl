function __LEX__tokenize(c::Cursor)::Vector{LexerToken}
  @debug "<<<<< START OF TOKENIZE >>>>>"
  tokens::Vector{LexerToken} = []
  while !cursor_is_eof(c)
    did_match::Bool = false
    for pattern in ACTION_PATTERNS
      matched = cursor_findnext_and_move(c, pattern)
      if matched === nothing
        continue
      end
      matched_txt = cursor_slice(c, matched)
      @debug "New match of length $(length(matched)) found: \"$(matched_txt)\" at $(cursor_file_position(c))"
      __LEX__current_match(matched_txt)

      token = PATTERN_TO_ACTION[pattern]()
      if token isa LexerToken
        @debug "New token has been created: $token"
        push!(tokens, token)
      end

      did_match = true
      break
    end

    if !did_match
      cursor_error(c, "Unrecognized token, did not match any pattern")
    end
  end

  @debug "<<<<<   END OF TOKENIZE >>>>>"
  push!(tokens, __LEX__EOI())
  return tokens
end