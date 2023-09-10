using Parameters: @consts

@enum Assoc left right
@enum Operator star plus question_mark alternation concatenation line_start line_end
@enum Token escaped_character operator character_class character left_paren right_paren concat

struct OperatorPrecedenceEntry
  prec::Int
  assoc::Assoc
end

@consts begin
  # See: https://pubs.opengroup.org/onlinepubs/9699919799/basedefs/V1_chap09.html#tag_09_04_08
  OperatorsPrecedenceTable::Dict{Operator, OperatorPrecedenceEntry} = Dict(
    # Escaped characters (6) (unary) handled by espaced char token
    # Brackets (5) handled by character class token
    # Grouping (4) handled by evaluate loop
    # Duplication (*, +, ?, {})
    star => OperatorPrecedenceEntry(3, left),
    plus => OperatorPrecedenceEntry(3, left),
    question_mark => OperatorPrecedenceEntry(3, left),
    # TODO: Add {} duplication
    # Concatenation
    concatenation => OperatorPrecedenceEntry(2, left),
    # Anchoring
    line_start => OperatorPrecedenceEntry(1, right),
    line_end => OperatorPrecedenceEntry(1, left),
    # Alternation
    alternation => OperatorPrecedenceEntry(0, left)
  )

  StringToOperator::Dict{String, Operator} = Dict(
    "*" => star,
    "+" => plus,
    "?" => question_mark,
    "|" => alternation,
    "^" => line_start,
    raw"$" => line_end
  )

  TokenPatterns::Vector{Pair{Token, Regex}} = [
    character => r"[^*+?|^$\\\(\)\[\]]",
    operator => r"[*+?|^$]",
    left_paren => r"\(",
    right_paren => r"\)",
    character_class => r"\[[^\]]+\]",
    escaped_character => r"\\[^ \t\n\r]",
  ]

  ConcatenationPairs::Set{Tuple{Token, Token}} = Set([
    (character, character),
    (character, character_class),
    (character, left_paren),
    (right_paren, character),
    (right_paren, character_class),
    (right_paren, left_paren),
    (operator, character),
    (operator, character_class),
    (operator, left_paren),
    (character_class, character),
    (character_class, character_class),
    (character_class, left_paren),
    # Escaped Chars also count as characters
    (character, escaped_character),
    (escaped_character, character),
    (escaped_character, escaped_character),
    (escaped_character, character_class),
    (escaped_character, left_paren),
    (right_paren, escaped_character),
    (operator, escaped_character),
    (character_class, escaped_character),
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
      @error "No token matched"
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
      insert!(tokens, insert_index, (concat, ""))
      insert_index += 1
    end
    insert_index += 1
  end

  return tokens
end
