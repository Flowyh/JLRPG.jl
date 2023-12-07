"""
    generate_lexer(definition_path::String, output_path::String="__LEX__.jl")

Generate a lexer source file from a lexer definition file.

The lexer definition file should follow the syntax described in both
`read_lexer_definition_file` and `SimpleLexer` module documentation.

By default parsers assume that there is a lexer file named `__LEX__.jl` in the
same directory as the parser file. The user may specify a different path by passing `output_path` argument. If another path is specified, it is required that the user
manually include the generated lexer file in the parser definition file.
"""
function generate_lexer(
  definition_path::String,
  output_path::String="__LEX__.jl"
)
  lexer = read_lexer_definition_file(definition_path)

  lexer = expand_regex_aliases_in_lexer(lexer)
  returned_tokens = retrieve_tokens_from_lexer(lexer)
  lexer = replace_token_args_in_lexer(lexer, returned_tokens)

  tag = lexer.options.tag
  output_path = replace(output_path, LEXER_SPECIAL_TAG => tag)

  open(output_path, "w") do output_file
    filled_template = fill_lexer_template(
      returned_tokens,
      lexer.code_blocks,
      lexer.actions
    )
    output = filled_template |>
      replace_special_variables_in_generated_lexer |>
      replace_overloaded_functions_in_generated_lexer |>
      x -> replace_special_tag_in_generated_lexer(x, tag)

    write(output_file, output)
  end

  println("Generated lexer path: $(output_path)")
  nothing
end

#============#
# PRECOMPILE #
#============#
precompile(generate_lexer, (
  String,
  String
))
