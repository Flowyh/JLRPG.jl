using Parameters: @consts

@consts begin
  LEXER_SPECIAL_VARIABLES_REPLACEMENTS::Vector{Pair} = [
    raw"$$line" => "__LEX__.line",
    raw"$$col" => "__LEX__.column",
    raw"$$" => "__LEX__.current_match"
  ]

  LEXER_SPECIAL_FUNCTIONS_PATTERNS = [r"__LEX__" * fn for fn in [
    r"at_end"
  ]]
end

function replace_special_variables_in_generated_lexer(
  generated_lexer::String
)::String
  for (special_variable, replacement) in LEXER_SPECIAL_VARIABLES_REPLACEMENTS
    generated_lexer = replace(generated_lexer, special_variable => replacement)
  end
  return generated_lexer
end

function replace_overloaded_functions_in_generated_lexer(
  generated_lexer::String
)::String
  for special_function in LEXER_SPECIAL_FUNCTIONS_PATTERNS
    found_overloads = findall(full_function_pattern(special_function), generated_lexer)
    if length(found_overloads) <= 1
      continue
    end
    # Only last overload applies
    for overload in found_overloads[1:end-1]
      generated_lexer = replace(generated_lexer, generated_lexer[overload] => "")
    end
  end

  return generated_lexer
end
