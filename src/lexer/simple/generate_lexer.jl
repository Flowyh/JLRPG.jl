function generate_lexer(
  definition_path::String,
  output_path::String="__LEX__.jl"
)
  lexer = nothing
  open(definition_path) do definition_file
    lexer = _read_lexer_definition_file(definition_file)
  end

  lexer = expand_regex_aliases_in_lexer(lexer)
  returned_tokens = retrieve_tokens_from_lexer(lexer)
  lexer = replace_token_args_in_lexer(lexer, returned_tokens)

  open(output_path, "w") do output_file
    filled_template = fill_lexer_template(
      returned_tokens,
      lexer.code_blocks,
      lexer.actions
    )
    output = filled_template |>
      replace_special_variables_in_generated_lexer |>
      replace_overloaded_functions_in_generated_lexer

    write(output_file, output)
  end
end

