using Parameters: @consts

# TODO: tests

@consts begin
  PARSER_SPECIAL_VARIABLES_REPLACEMENTS::Vector{Pair} = [
    raw"$$" => "__PAR__action_result"
    r"\$(\d+)" => s"__PAR__symbols_slice[\1]"
  ]

  PARSER_SPECIAL_FUNCTION_PREFIX = r"__PAR__"

  PARSER_SPECIAL_FUNCTIONS_PATTERNS = [PARSER_SPECIAL_FUNCTION_PREFIX * fn for fn in [
    r"at_end",
    r"main",
    r"usage"
  ]]
end

function replace_special_variables_in_generated_parser(
  generated_parser::String
)::String
  for (special_variable, replacement) in PARSER_SPECIAL_VARIABLES_REPLACEMENTS
    generated_parser = replace(generated_parser, special_variable => replacement)
  end
  return generated_parser
end

function replace_overloaded_functions_in_generated_parser(
  generated_parser::String
)::String
  for special_function in PARSER_SPECIAL_FUNCTIONS_PATTERNS
    found_overloads = findall(full_function_pattern(special_function), generated_parser)
    if length(found_overloads) <= 1
      continue
    end
    # Only last overload applies
    for overload in found_overloads[1:end-1]
      generated_parser = replace(generated_parser, generated_parser[overload] => "")
    end
  end

  return generated_parser
end
