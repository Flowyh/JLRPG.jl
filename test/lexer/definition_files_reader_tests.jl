@testset "Definition files reader" begin
  @testset "Throws errors for invalid definition files" begin
    @testset "Empty file" begin
      @test_throws "Invalid definition file, not enough sections" read_definition_file(from_current_path("resources/lexer/definition_reader/empty_file.jlex"))
    end
  end

  @testset "Correctly parses definition files" begin
    @testset "Empty sections" begin
      lexer = read_definition_file(from_current_path("resources/lexer/definition_reader/empty_sections.jlex"))
      @test lexer.actions == []
      @test lexer.aliases == []
      @test lexer.code_blocks == []
      @test lexer.options == Options()
    end

    @testset "Only actions" begin
      lexer = read_definition_file(from_current_path("resources/lexer/definition_reader/only_actions.jlex"))
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
      lexer = read_definition_file(from_current_path("resources/lexer/definition_reader/all_sections.jlex"))
      @test lexer.actions == [
        Action("{WHITESPACE}", " test += 1 "),
        Action("{NUM}", "\n  test += 2\n  return Num(5)\n"),
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
end
