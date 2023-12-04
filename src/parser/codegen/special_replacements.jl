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
    found_overloads = findall(function_definition(special_function), generated_parser)
    if length(found_overloads) <= 1
      continue
    end
    fn_name = match(function_name, generated_parser[found_overloads[1]])[:name]
    fn_name = replace(fn_name, PARSER_SPECIAL_FUNCTION_PREFIX => "")

    # Replace code between start and end for # <<: OVERLOADED :>>
    to_replace   = SPECIAL_FUNCTION_START(fn_name) *
                   r"[\S\s]*" *
                   SPECIAL_FUNCTION_END(fn_name)
    replaced_msg = SPECIAL_FUNCTION_OVERLOAD_MSG(fn_name)

    generated_parser = replace(generated_parser, to_replace => replaced_msg)
  end

  return generated_parser
end
