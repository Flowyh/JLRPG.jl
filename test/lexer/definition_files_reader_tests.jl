@testset "Definition files reader" begin
  @testset "Throws errors for invalid definition files" begin
    @testset "Empty file" begin
      @test_throws "Invalid definition file, not enough sections" read_lexer_definition_file(abspaths("resources/lexer/definition_reader/empty_file.jlex"))
    end

    @testset "Not enough sections" begin
      @test_throws "Invalid definition file, not enough sections" read_lexer_definition_file(abspaths("resources/lexer/definition_reader/not_enough_sections.jlex"))
    end

    @testset "Option outside definitions" begin
      path = abspaths("resources/lexer/definition_reader/option_outside_definitions.jlex")
      error_msg = raw"Option %option misplaced outside of definitions section" * "\n" * 
                  raw"       \"%option misplaced\" at " * "$(unexpanduser(path)):5:18"
      @test_throws error_msg read_lexer_definition_file(path)
    end

    @testset "Regex alias outside definitions" begin
      path = abspaths("resources/lexer/definition_reader/regex_alias_outside_definitions.jlex")
      error_msg = raw"Regex alias WHITESPACE [ \t\r\n]+ outside of definitions section" * "\n" * 
                  raw"       \"WHITESPACE [ \t\r\n]+\" at " * "$(unexpanduser(path)):5:22"
      @test_throws error_msg read_lexer_definition_file(path)
    end

    @testset "Action outside actions" begin
      path = abspaths("resources/lexer/definition_reader/action_outside_actions.jlex")
      error_msg = raw"Action \"test\" { return Test($$) } outside of actions section" * "\n" * 
                  raw"       \"\"test\" { return Test($$) }\" at " * "$(unexpanduser(path)):3:27"
      @test_throws error_msg read_lexer_definition_file(path)
    end

    @testset "Invalid char/s inside definition file" begin
      path = abspaths("resources/lexer/definition_reader/invalid_chars.jlex")
      error_msg = "Invalid character/s in definition file" * "\n" * 
                  "       \"/\" at $(unexpanduser(path)):3:43"
      @test_throws error_msg read_lexer_definition_file(path)
    end

    @testset "Actions with empty patterns are invalid" begin
      path = abspaths("resources/lexer/definition_reader/empty_action_pattern.jlex")
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
