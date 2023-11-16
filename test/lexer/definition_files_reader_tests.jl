@testset "Definition files reader" begin
  @testset "Throws errors for invalid definition files" begin
    @testset "Empty file" begin
      path = abspaths("resources/lexer/definition_reader/erroneous/empty_file.jlex")
      error_msg = "Invalid definition file, not enough sections"
      @test_throws error_msg read_lexer_definition_file(path)
    end

    @testset "Not enough sections" begin
      path = abspaths("resources/lexer/definition_reader/erroneous/not_enough_sections.jlex")
      error_msg = "Invalid definition file, not enough sections"
      @test_throws error_msg read_lexer_definition_file(path)
    end

    @testset "Option outside definition section" begin
      path = abspaths("resources/lexer/definition_reader/erroneous/option_outside_definitions.jlex")
      error_msg = raw"Option outside of definitions section" * "\n" *
                  raw"       \"%option misplaced\" at " * "$(unexpanduser(path)):5:1"
      @test_throws error_msg read_lexer_definition_file(path)
    end

    @testset "Regex alias outside definition section" begin
      path = abspaths("resources/lexer/definition_reader/erroneous/regex_alias_outside_definitions.jlex")
      error_msg = raw"Regex alias outside of definitions section" * "\n" *
                  raw"       \"WHITESPACE [ \t\r\n]+\" at " * "$(unexpanduser(path)):5:1"
      @test_throws error_msg read_lexer_definition_file(path)
    end

    @testset "Action outside actions section" begin
      path = abspaths("resources/lexer/definition_reader/erroneous/action_outside_actions.jlex")
      error_msg = raw"Action outside of actions section" * "\n" *
                  raw"       \"\"test\" { return Test($$) }\" at " * "$(unexpanduser(path)):3:1"
      @test_throws error_msg read_lexer_definition_file(path)
    end

    @testset "Invalid character/s in definition file" begin
      path = abspaths("resources/lexer/definition_reader/erroneous/invalid_chars.jlex")
      error_msg = "Invalid character/s in definition file" * "\n" *
                  "       \"/\" at $(unexpanduser(path)):3:43"
      @test_throws error_msg read_lexer_definition_file(path)
    end

    @testset "Actions with empty patterns are invalid" begin
      path = abspaths("resources/lexer/definition_reader/erroneous/empty_action_pattern.jlex")
      error_msg = "Invalid character/s in definition file" * "\n" *
                  "       \"{\" at $(unexpanduser(path)):5:8"
      @test_throws error_msg read_lexer_definition_file(path)
    end
  end

  @testset "Correctly parses definition files" begin
    @testset "Empty sections" begin
      lexer = read_lexer_definition_file(abspaths("resources/lexer/definition_reader/empty_sections.jlex"))
      @test lexer.actions == []
      @test lexer.aliases == []
      @test lexer.code_blocks == []
      @test lexer.options == LexerOptions()
    end

    @testset "Too many sections" begin
      lexer = read_lexer_definition_file(abspaths("resources/lexer/definition_reader/too_many_sections.jlex"))
      @test lexer.actions == []
      @test lexer.aliases == []
      @test lexer.code_blocks == ["%%\n\n%%\n\n%%\n\n%%"]
      @test lexer.options == LexerOptions()
    end

    @testset "Only actions" begin
      lexer = read_lexer_definition_file(abspaths("resources/lexer/definition_reader/only_actions.jlex"))
      @test lexer.actions == [
        LexerAction("\"Test\"", " return \"Test\" "),
        LexerAction("[0-9]+", " return Number(\$\$) "),
        LexerAction(".*", " return Error() "),
      ]
      @test lexer.aliases == []
      @test lexer.code_blocks == []
      @test lexer.options == LexerOptions()
    end

    @testset "All sections present" begin
      lexer = read_lexer_definition_file(abspaths("resources/lexer/definition_reader/all_sections.jlex"))
      @test lexer.actions == [
        LexerAction("{WHITESPACE}", " test += 1 "),
        LexerAction("{NUM}", "\n  test += 2\n  return Num(5)\n"),
        LexerAction("\"text\"{NUM}", " test += 3 "),
        LexerAction("\"+\"", " return Operator(\"+\") "),
        LexerAction(".*", " return Error() ")
      ]
      @test lexer.aliases == [
        RegexAlias(:WHITESPACE, raw"[ \t\r]+"),
        RegexAlias(:NUM, "[0-9]+"),
        RegexAlias(:IDENTIFIER, "[_a-z]+")
      ]
      @test lexer.code_blocks == [
        "include(\"test\")\n\n  test::Int = 5\n  test2::Vector{String} = [\"abc\", \"def\"]",
        "println(\"Code in actions :o\")",
        "function factorial(n::Int)::Int\n  return n * factorial(n - 1)\nend"
      ]
      @test lexer.options == LexerOptions()
    end
  end
end
