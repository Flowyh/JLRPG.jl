@testset "Alias expansion" begin
  @testset "Throws errors for invalid aliases" begin
    @testset "Aliases should be defined before they are used" begin
      lexer = read_lexer_definition_file(abspaths("resources/lexer/alias_expansion/invalid_order_regex_aliases.jlex"))
      @test_throws "Invalid definition file, alias for NUM was referenced before it was defined" expand_regex_aliases_in_lexer(lexer)
    end

    @testset "Detect non-existent aliases in actions" begin
      lexer = read_lexer_definition_file(abspaths("resources/lexer/alias_expansion/non_existent_alias_in_actions.jlex"))
      expanded_aliases = expand_regex_aliases_in_aliases(lexer.aliases)
      @test expanded_aliases == [
        RegexAlias(:WHITESPACE, raw"[ \t\r]+"),
        RegexAlias(:NUM, "[0-9]"),
        RegexAlias(:IDENTIFIER, "[_a-zA-Z]([_a-zA-Z]|[0-9])+")
      ]

      @test_throws "Invalid definition file, alias for NON_EXISTENT is not defined" expand_regex_aliases_in_actions(lexer.actions, expanded_aliases)
    end

    @testset "Detect redefinition of aliases" begin
      lexer = read_lexer_definition_file("resources/lexer/alias_expansion/redefined_alias.jlex")
      @test_throws "Invalid definition file, alias WHITESPACE has already been defined" expand_regex_aliases_in_lexer(lexer)
    end
  end

  @testset "Correctly expands regex aliases" begin
    @testset "Empty aliases" begin
      lexer = read_lexer_definition_file(abspaths("resources/lexer/definition_reader/empty_sections.jlex"))
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
      lexer = read_lexer_definition_file(abspaths("resources/lexer/alias_expansion/regex_aliases.jlex"))
      expanded_aliases = expand_regex_aliases_in_aliases(lexer.aliases)
      @test expanded_aliases == [
        RegexAlias(:WHITESPACE, raw"[ \t\r]+"),
        RegexAlias(:NUM, "[0-9]"),
        RegexAlias(:IDENTIFIER, "[_a-zA-Z]([_a-zA-Z]|[0-9])+")
      ]
    end

    @testset "Actions with regex aliases" begin
      lexer = read_lexer_definition_file(abspaths("resources/lexer/alias_expansion/action_aliases.jlex"))
      expanded_aliases = expand_regex_aliases_in_aliases(lexer.aliases)
      @test expanded_aliases == [
        RegexAlias(:WHITESPACE, raw"\s"),
        RegexAlias(:DIGIT, "[0-9]"),
        RegexAlias(:NON_ZERO_DIGIT, "[1-9]"),
        RegexAlias(:NUMBER, "0|[1-9]+[0-9]*"),
        RegexAlias(:CHAR, "[_a-zA-Z]"),
        RegexAlias(:IDENTIFIER, "[_a-zA-Z]([_a-zA-Z]|[0-9])*")
      ]

      expanded_actions = expand_regex_aliases_in_actions(lexer.actions, expanded_aliases)
      @test expanded_actions == [
        LexerAction("[_a-zA-Z]([_a-zA-Z]|[0-9])*", raw"return Id($$)"),
        LexerAction("0|[1-9]+[0-9]*", raw"return Number($$)"),
        LexerAction(raw"\Q**HELLO**\E\s+\Q++WORLD++\E", "return Hello()"),
        LexerAction(".*", "return Error()"),
        LexerAction(raw"\Qa\E              \Qb\E", "return AB()")
      ]
    end
  end
end
