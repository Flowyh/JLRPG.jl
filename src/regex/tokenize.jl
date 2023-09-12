using Parameters: @consts

@enum Token escaped_character operator character_class character any_character left_paren right_paren

@consts begin
  TokenPatterns::Vector{Pair{Token, Regex}} = [
    character => r"[^*+?|^$\\\(\)\[\].]",
    operator => r"[*+?|^$]",
    left_paren => r"\(",
    right_paren => r"\)",
    character_class => r"\[[^\]]+\]",
    escaped_character => r"\\[^ \t\n\r]",
    any_character => r"\."
  ]

  Charlike::Vector{Token} = [character, escaped_character, any_character]
  ConcatenationPairs::Set{Tuple{Token, Token}} = Set([
    # Characters/Escaped chars/Any chars concatenated with each other
    [(i, j) for i in Charlike
            for j in Charlike]...,
    # Operators
    (right_paren, character_class),
    (right_paren, left_paren),
    (operator, character_class),
    (operator, left_paren),
    (character_class, character_class),
    (character_class, left_paren),
    ### Left-side concat with classes/left parens
    [(i, j) for i in Charlike
            for j in [character_class, left_paren]]...,
    # Right-side concat with right parens, operators, classes
    [(i, j) for i in [right_paren, operator, character_class]
            for j in Charlike]...,
  ])

  NotToConcatenateOps::Set{String} = Set(["|", "^", raw"$"])
end

function tokenize(regex::String)
  tokens::Vector{Tuple{Token, String}} = []
  cursor = 1
  while cursor <= length(regex)
    match::Bool = false
    for (token, pattern) in TokenPatterns
      matched = findnext(pattern, regex, cursor)
      if matched !== nothing && matched.start == cursor
        push!(tokens, (token, regex[matched]))
        cursor += length(regex[matched])
        match = true
        break
      end
    end
    if !match
      error("Invalid token, no match")
    end
  end

  if (length(tokens) == 1)
    return tokens
  end

  # Now add concatenation between correct tokens/operators.
  # Go through two tokens at a time and add concatenation if needed.
  # For possible cases, see: ConcatenationPairs
  insert_index = 2
  for (token_1, token_2) in zip(tokens[1:end-1], tokens[2:end])
    (left_token, left_lexem)   = token_1
    (right_token, right_lexem) = token_2
    if !(left_token == operator  && left_lexem in NotToConcatenateOps) && 
       !(right_token == operator && right_lexem in NotToConcatenateOps) &&
       (left_token, right_token) in ConcatenationPairs
    # end of if
      insert!(tokens, insert_index, (operator, ""))
      insert_index += 1
    end
    insert_index += 1
  end

  return tokens
end
