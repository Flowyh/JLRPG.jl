@testset "Simple lexer" begin
  @testset "Correctly parses definition files" begin
    @testset "Empty file" begin
      @test_throws "Invalid definition file, not enough sections" read_definition_file(from_current_path("resources/lexer/empty_file.jlex"))
    end

    @testset "Empty sections" begin
      lexer = read_definition_file(from_current_path("resources/lexer/empty_sections_lexer.jlex"))
      @test lexer.actions == []
      @test lexer.aliases == []
      @test lexer.code_blocks == []
      @test lexer.options == Options()
    end

    @testset "Only actions" begin
      lexer = read_definition_file(from_current_path("resources/lexer/only_actions_lexer.jlex"))
      @test lexer.actions == [
        Action("\"Test\"", " return \"Test\" "),
        Action("[0-9]+", " return Number(\$\$) "),
        Action(".*", " return Error() "),
        Action(" ", " return AlsoValid() ")
      ]
      @test lexer.aliases == []
      @test lexer.code_blocks == []
      @test lexer.options == Options()
    end

    @testset "All sections present" begin
      lexer = read_definition_file(from_current_path("resources/lexer/all_sections_lexer.jlex"))
      @test lexer.actions == [
        Action("{WHITESPACE}", " test += 1 "),
        Action("{NUM}", " \n  test += 2\n  return Num(5) \n"),
        Action("\"text\"{NUM}", " test += 3 "),
        Action("\"+\"", " return Operator(\"+\") "),
        Action(".*", " return Error() ")
      ]
      @test lexer.aliases == [
        RegexAlias(:WHITESPACE, raw"[ \t\r]+"),
        RegexAlias(:NUM, "[0-9]+"),
        RegexAlias(:IDENTIFIER, "[_a-z]+")
      ]
      @test lexer.code_blocks == [
        "  include(\"test\")\n\n  test::Int = 5\n  test2::Vector{String} = [\"abc\", \"def\"]\n",
        "  println(\"Code in actions :o\")\n",
        "\n\nfunction factorial(n::Int)::Int\n  return n * factorial(n - 1)\nend\n"
      ]
      @test lexer.options == Options()
    end
  end

  @testset "Correctly expands regex aliases" begin
    @testset "Empty sections" begin
      lexer = read_definition_file(from_current_path("resources/lexer/empty_sections_lexer.jlex"))
      expanded_aliases = expand_regex_aliases_in_aliases(lexer.aliases)
      @test expanded_aliases == []

      expanded_actions = expand_regex_aliases_in_actions(lexer.actions, expanded_aliases)
      @test expanded_actions == []

      expanded_lexer = expand_regex_aliases_in_lexer(lexer)
      @test lexer.actions == expanded_lexer.actions
      @test lexer.aliases == expanded_lexer.aliases
      @test lexer.code_blocks == expanded_lexer.code_blocks
      @test lexer.options == expanded_lexer.options
    end

    @testset "Simple regex aliases" begin
      lexer = read_definition_file(from_current_path("resources/lexer/alias_expansion/regex_aliases_lexer.jlex"))
      expanded_aliases = expand_regex_aliases_in_aliases(lexer.aliases)
      @test expanded_aliases == [
        RegexAlias(:WHITESPACE, raw"[ \t\r]+"),
        RegexAlias(:NUM, "[0-9]"),
        RegexAlias(:IDENTIFIER, "[_a-zA-Z]([_a-zA-Z]|[0-9])+")
      ]
    end

    @testset "Aliases should be defined before they are used" begin
      lexer = read_definition_file(from_current_path("resources/lexer/alias_expansion/invalid_order_regex_aliases_lexer.jlex"))
      @test_throws "Invalid definition file, alias for NUM was referenced before it was defined" expand_regex_aliases_in_lexer(lexer)
    end

    @testset "Actions with regex aliases" begin
      lexer = read_definition_file(from_current_path("resources/lexer/alias_expansion/action_aliases_lexer.jlex"))
      expanded_aliases = expand_regex_aliases_in_aliases(lexer.aliases)
      @test expanded_aliases == [
        RegexAlias(:WHITESPACE, raw"[ \t\r]+"),
        RegexAlias(:NUM, "[0-9]"),
        RegexAlias(:IDENTIFIER, "[_a-zA-Z]([_a-zA-Z]|[0-9])+")
      ]

      expanded_actions = expand_regex_aliases_in_actions(lexer.actions, expanded_aliases)
      @test expanded_actions == [
        Action("[_a-zA-Z]([_a-zA-Z]|[0-9])+", raw" return Id($$) "),
        Action("[0-9]+", raw" return Number($$) "),
        Action(raw"HELLO[ \t\r]+WORLD", " return Hello() "),
        Action(".*", " return Error() "),
        Action("a              b", " return AB() ")
      ]
    end

    @testset "Detect invalid aliases in actions" begin
      lexer = read_definition_file(from_current_path("resources/lexer/alias_expansion/invalid_alias_in_actions_lexer.jlex"))
      expanded_aliases = expand_regex_aliases_in_aliases(lexer.aliases)
      @test expanded_aliases == [
        RegexAlias(:WHITESPACE, raw"[ \t\r]+"),
        RegexAlias(:NUM, "[0-9]"),
        RegexAlias(:IDENTIFIER, "[_a-zA-Z]([_a-zA-Z]|[0-9])+")
      ]

      @test_throws "Invalid definition file, alias for NON_EXISTENT is not defined" expand_regex_aliases_in_actions(lexer.actions, expanded_aliases)
    end
  end
end
