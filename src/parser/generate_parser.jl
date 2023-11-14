function generate_parser(
  definition_path::String,
  output_path::String="__PAR__.jl"
)
  parser = nothing
  open(definition_path) do definition_file
    parser = _read_parser_definition_file(definition_file)
  end

  parser = augment_parser(parser)
  table = SlrParsingTable(parser)

  open(output_path, "w") do output_file
    filled_template = fill_parser_template(
      parser.code_blocks,
      table,
      parser.productions,
      parser.symbol_types
    )
    output = filled_template |>
      replace_special_variables_in_generated_parser |>
      replace_overloaded_functions_in_generated_parser

    write(output_file, output)
  end
end
