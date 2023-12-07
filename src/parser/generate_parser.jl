"""
    generate_parser(definition_path::String, output_path::String="__PAR__.jl")

Generate a parser source file from a parser definition file.

The parser definition file should follow the syntax described in both
`read_parser_definition_file` and `Parser` module documentation.
"""
function generate_parser(
  definition_path::String,
  output_path::String="__PAR__.jl"
)
  parser = read_parser_definition_file(definition_path)
  parser = augment_parser(parser)

  if parser.options.parser_type == SLR
    table = SlrParsingTable(parser)
  elseif parser.options.parser_type == LR
    table = LrParsingTable(parser)
  elseif parser.options.parser_type == LALR
    table = LalrParsingTable(parser)
  else
    error("Unknown parser type: $(parser.options.parser_type)")
  end

  tag = parser.options.tag
  lexer_tag = parser.options.lexer_tag
  output_path = replace(output_path, PARSER_SPECIAL_TAG => tag)

  open(output_path, "w") do output_file
    filled_template = fill_parser_template(
      parser.code_blocks,
      table,
      parser.productions,
      parser.symbol_types
    )

    output = filled_template |>
      replace_special_variables_in_generated_parser |>
      replace_overloaded_functions_in_generated_parser |>
      x -> replace_special_tag_in_generated_parser(x, tag, lexer_tag)

    write(output_file, output)
  end

  println("Generated parser path: $(output_path)")
  nothing
end
