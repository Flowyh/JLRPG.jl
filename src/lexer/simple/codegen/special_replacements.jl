using Parameters: @consts

@consts begin
  LEXER_SPECIAL_VARIABLES_REPLACEMENTS::Vector{Pair} = [
    raw"$$" => "__LEX__current_match()"
  ]

  # Special tag used to mark lexer functions and variables.
  # This tag is used to avoid name collisions with user-defined functions.
  LEXER_SPECIAL_TAG = r"__LEX__"

  LEXER_SPECIAL_FUNCTIONS_PATTERNS = [LEXER_SPECIAL_TAG * fn for fn in [
    r"at_end",
    r"main"
  ]]
end

"""
    replace_special_variables_in_generated_lexer(
      generated_lexer::String
    )::String

Replace special variables in the generated lexer code.

Currently the only special variable is `\$\$`, which is replaced with
`__LEX__current_match()`.
"""
function replace_special_variables_in_generated_lexer(
  generated_lexer::String
)::String
  for (special_variable, replacement) in LEXER_SPECIAL_VARIABLES_REPLACEMENTS
    generated_lexer = replace(generated_lexer, special_variable => replacement)
  end
  return generated_lexer
end

"""
    replace_overloaded_functions_in_generated_lexer(
      generated_lexer::String
    )::String

Replace overloaded functions in the generated lexer code.

Scan the generated lexer code for overloaded functions and replace the sections
between `# <<: ovearloaded_func start :>>` and `# <<: ovearloaded_func end :>>` 
with a message that the function is overloaded.
"""
function replace_overloaded_functions_in_generated_lexer(
  generated_lexer::String
)::String
  for special_function in LEXER_SPECIAL_FUNCTIONS_PATTERNS
    found_overloads = findall(function_definition(special_function), generated_lexer)
    if length(found_overloads) <= 1
      continue
    end
    fn_name = match(function_name, generated_lexer[found_overloads[1]])[:name]
    fn_name = replace(fn_name, LEXER_SPECIAL_TAG => "")

    # Replace code between start and end for # <<: OVERLOADED :>>
    to_replace   = SPECIAL_FUNCTION_START(fn_name) *
                   r"[\S\s]*" *
                   SPECIAL_FUNCTION_END(fn_name)
    replaced_msg = SPECIAL_FUNCTION_OVERLOAD_MSG(fn_name)

    generated_lexer = replace(generated_lexer, to_replace => replaced_msg)
  end

  return generated_lexer
end

"""
    replace_special_tag_in_generated_lexer(
      generated_lexer::String,
      tag::String
    )::String

Replace special tag in the generated lexer code.

This function is used to replace the special prefix present in all generated objects
with the user-defined tag.
"""
function replace_special_tag_in_generated_lexer(
  generated_lexer::String,
  tag::String
)::String
  if tag != LEXER_SPECIAL_TAG
    generated_lexer = replace(
      generated_lexer,
      LEXER_SPECIAL_TAG => tag
    )
  end
  return generated_lexer
end

#============#
# PRECOMPILE #
#============#
precompile(replace_special_variables_in_generated_lexer, (
  String,
))
precompile(replace_overloaded_functions_in_generated_lexer, (
  String,
))
precompile(replace_special_tag_in_generated_lexer, (
  String, 
  String
))
