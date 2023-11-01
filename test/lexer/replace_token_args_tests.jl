@testset "Replacing returned tokens' arguments for special kwargs" begin
  @testset "Throws errors for invalid tokens returned in lexer actions" begin

  end

  @testset "Correctly retrieves tokens from actions" begin
    @testset "Empty actions" begin
      lexer = read_lexer_definition_file(from_current_path("resources/lexer/definition_reader/empty_sections.jlex"))

      returned_tokens = retrieve_tokens_from_lexer(lexer)
      lexer = replace_token_args_in_lexer(lexer, returned_tokens)
      @test lexer.actions == []
    end

    @testset "Tokens without typing and naming" begin
      lexer = read_lexer_definition_file(from_current_path("resources/lexer/token_retrieval/simple_tokens.jlex"))

      returned_tokens = retrieve_tokens_from_lexer(lexer)
      lexer = replace_token_args_in_lexer(lexer, returned_tokens)
      @test lexer.actions == [
        LexerAction("\"5\"", " return Five(;value=convert_type(String, 5)) "),
        LexerAction("\"123\"", " return OneTwoThree(;value1=convert_type(String, 1), value2=convert_type(String, 2), value3=convert_type(String, 3)) "),
        LexerAction("[0-9]", raw" return Digit(;value=convert_type(String, $$)) "),
        LexerAction("\"def\"", raw" return Function(;value=convert_type(String, func($$))) "),
        LexerAction(".*", " return Error() ")
      ]
    end

    @testset "Tokens with typing, without naming" begin
      lexer = read_lexer_definition_file(from_current_path("resources/lexer/token_retrieval/typed_tokens.jlex"))

      returned_tokens = retrieve_tokens_from_lexer(lexer)
      lexer = replace_token_args_in_lexer(lexer, returned_tokens)
      @test lexer.actions == [
        LexerAction("\"5.0\"", " return Five(;value=convert_type(Float64, 5.0)) "),
        LexerAction("\"123\"", " return OneTwoThree(;value1=convert_type(Int, 1), value2=convert_type(Float32, 2), value3=convert_type(Int16, 3)) "),
        LexerAction("[0-9]", raw" return Digit(;value=convert_type(Int, $$)) "),
        LexerAction("\"def\"", raw" return Function(;value=convert_type(String, func($$))) "),
        LexerAction("[a-zA-Z]+", raw" return Message(;value=convert_type(String, $$)) "),
        LexerAction(".*", " return Error() ")
      ]
    end

    @testset "Tokens with typing and naming" begin
      lexer = read_lexer_definition_file(from_current_path("resources/lexer/token_retrieval/typed_named_tokens.jlex"))

      returned_tokens = retrieve_tokens_from_lexer(lexer)
      lexer = replace_token_args_in_lexer(lexer, returned_tokens)
      @test lexer.actions == [
        LexerAction("\"5.0\"", " return Five(;five=convert_type(Float64, 5.0)) "),
        LexerAction("\"123\"", " return OneTwoThree(;one=convert_type(Int, 1), two=convert_type(Float32, 2), three=convert_type(Int16, 3)) "),
        LexerAction("[0-9]", raw" return Digit(;value=convert_type(Int, $$)) "),
        LexerAction("\"def\"", raw" return Function(;func_call=convert_type(String, func($$))) "),
        LexerAction("[a-zA-Z]+", raw" return Message(;msg=convert_type(String, $$)) "),
        LexerAction(".*", " return Error() ")
      ]
    end

    @testset "All tokens" begin
      lexer = read_lexer_definition_file(from_current_path("resources/lexer/token_retrieval/all_tokens.jlex"))

      returned_tokens = retrieve_tokens_from_lexer(lexer)
      lexer = replace_token_args_in_lexer(lexer, returned_tokens)
      @test lexer.actions == [
        LexerAction("\"invalid return\"", " return Omitted "),
        LexerAction("\"missing parenthesis\"", " return Omitted( "),
        LexerAction("[0-9]", raw" return Digit(;value=convert_type(String, $$)) "),
        LexerAction("[0-9]+", raw" return Number(;value=convert_type(Int, $$)) "),
        LexerAction("[_a-zA-Z][_a-zA-Z0-9]*", raw" return Identifier(;name=convert_type(String, $$), line=convert_type(Int, 15)) "),
        LexerAction(".*", raw" return Error(;match=convert_type(String, $$)) ")
      ]
    end
  end
end
