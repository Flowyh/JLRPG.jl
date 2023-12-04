function __LEX__tokenize()::Vector{LexerToken}
  @debug "<<<<< START OF TOKENIZE >>>>>"
  tokens::Vector{LexerToken} = []
  c::Cursor = __LEX__cursor()
  while !cursor_is_eof(c)
    did_match::Bool = false
    for pattern in __LEX__ACTION_PATTERNS
      __LEX__set_file_pos_before_match(cursor_file_position(c))
      matched::Union{Nothing, UnitRange{Int}} = cursor_findnext_and_move(c, pattern)
      if matched === nothing
        continue
      end
      matched_txt::String = cursor_slice(c, matched)
      @debug "New match of length $(length(matched)) found: \"$(matched_txt)\" at $position"
      __LEX__set_current_match(matched_txt)

      token = __LEX__PATTERN_TO_ACTION[pattern]()
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