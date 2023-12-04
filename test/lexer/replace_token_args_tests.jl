@testset "Replacing returned tokens' arguments for special kwargs" begin
  @testset "Throws errors for invalid tokens returned in lexer actions" begin

  end

  @testset "Correctly retrieves tokens from actions" begin
    @testset "Empty actions" begin
      lexer = read_lexer_definition_file(abspaths("resources/lexer/definition_reader/empty_sections.jlex"))

      returned_tokens = retrieve_tokens_from_lexer(lexer)
      lexer = replace_token_args_in_lexer(lexer, returned_tokens)
      @test lexer.actions == []
    end

    @testset "Tokens without typing and naming" begin
      lexer = read_lexer_definition_file(abspaths("resources/lexer/token_retrieval/simple_tokens.jlex"))

      returned_tokens = retrieve_tokens_from_lexer(lexer)
      lexer = replace_token_args_in_lexer(lexer, returned_tokens)
      @test lexer.actions == [
        LexerAction("\"5\"", "return __LEX__Five(;value=5)"),
        LexerAction("\"123\"", "return __LEX__OneTwoThree(;value1=1, value2=2, value3=3)"),
        LexerAction("[0-9]", raw"return __LEX__Digit(;value=$$)"),
        LexerAction("\"def\"", raw"return __LEX__Function(;value=func($$))"),
        LexerAction(".*", "return __LEX__Error()")
      ]
    end

    @testset "Tokens with typing, without naming" begin
      lexer = read_lexer_definition_file(abspaths("resources/lexer/token_retrieval/typed_tokens.jlex"))

      returned_tokens = retrieve_tokens_from_lexer(lexer)
      lexer = replace_token_args_in_lexer(lexer, returned_tokens)
      @test lexer.actions == [
        LexerAction("\"5.0\"", "return __LEX__Five(;value=5.0)"),
        LexerAction("\"123\"", "return __LEX__OneTwoThree(;value1=1, value2=2, value3=3)"),
        LexerAction("[0-9]", raw"return __LEX__Digit(;value=$$)"),
        LexerAction("\"def\"", raw"return __LEX__Function(;value=func($$))"),
        LexerAction("[a-zA-Z]+", raw"return __LEX__Message(;value=$$)"),
        LexerAction(".*", "return __LEX__Error()")
      ]
    end

    @testset "Tokens with typing and naming" begin
      lexer = read_lexer_definition_file(abspaths("resources/lexer/token_retrieval/typed_named_tokens.jlex"))

      returned_tokens = retrieve_tokens_from_lexer(lexer)
      lexer = replace_token_args_in_lexer(lexer, returned_tokens)
      @test lexer.actions == [
        LexerAction("\"5.0\"", "return __LEX__Five(;five=5.0)"),
        LexerAction("\"123\"", "return __LEX__OneTwoThree(;one=1, two=2, three=3)"),
        LexerAction("[0-9]", raw"return __LEX__Digit(;value=$$)"),
        LexerAction("\"def\"", raw"return __LEX__Function(;func_call=func($$))"),
        LexerAction("[a-zA-Z]+", raw"return __LEX__Message(;msg=$$)"),
        LexerAction(".*", "return __LEX__Error()")
      ]
    end

    @testset "All tokens" begin
      lexer = read_lexer_definition_file(abspaths("resources/lexer/token_retrieval/all_tokens.jlex"))

      returned_tokens = retrieve_tokens_from_lexer(lexer)
      lexer = replace_token_args_in_lexer(lexer, returned_tokens)
      @test lexer.actions == [
        LexerAction("\"invalid return\"", "return Omitted"),
        LexerAction("\"missing parenthesis\"", "return Omitted("),
        LexerAction("[0-9]", raw"return __LEX__Digit(;value=$$)"),
        LexerAction("[0-9]+", raw"return __LEX__Number(;value=$$)"),
        LexerAction("[_a-zA-Z][_a-zA-Z0-9]*", raw"return __LEX__Identifier(;name=$$, line=15)"),
        LexerAction("\"all arg types\"", "return __LEX__AllArgs(;a=1, value2=2.0, value3=\"3\")"),
        LexerAction(".*", raw"return __LEX__Error(;match=$$)")
      ]
    end
  end
end
