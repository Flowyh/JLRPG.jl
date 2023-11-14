@testset "Token retrevial from lexer actions" begin
  @testset "Throws errors for invalid tokens returned in lexer actions" begin
    @testset "Redefined arguments in tokens" begin
      lexer = read_lexer_definition_file(abspaths("resources/lexer/token_retrieval/redefined_args_tokens.jlex"))
      @test_throws "Token OneTwoThree has duplicate arguments: [:one, :one, :one]" retrieve_tokens_from_lexer(lexer)
    end

    @testset "Redefined token with different arguments" begin
      lexer = read_lexer_definition_file(abspaths("resources/lexer/token_retrieval/redefined_token_with_different_args.jlex"))
      @test_throws "Token OneTwoThree has been redefined with different arguments" retrieve_tokens_from_lexer(lexer)
    end
  end

  @testset "Correctly retrieves tokens from actions" begin
    @testset "Empty actions" begin
      lexer = read_lexer_definition_file(abspaths("resources/lexer/definition_reader/empty_sections.jlex"))

      returned_tokens = retrieve_tokens_from_lexer(lexer)
      @test returned_tokens == []
    end

    @testset "Tokens without typing and naming" begin
      lexer = read_lexer_definition_file(abspaths("resources/lexer/token_retrieval/simple_tokens.jlex"))

      returned_tokens = retrieve_tokens_from_lexer(lexer)
      @test returned_tokens == [
        LexerTokenDefinition(:Five, [(name=:value, type=:String, value="5")]),
        LexerTokenDefinition(
          :OneTwoThree,
          [
            (name=:value1, type=:String, value="1"),
            (name=:value2, type=:String, value="2"),
            (name=:value3, type=:String, value="3")
          ]
        ),
        LexerTokenDefinition(:Digit, [(name=:value, type=:String, value=raw"$$")]),
        LexerTokenDefinition(:Function, [(name=:value, type=:String, value=raw"func($$)")]),
        LexerTokenDefinition(:Error, [])
      ]
    end

    @testset "Tokens with typing, without naming" begin
      lexer = read_lexer_definition_file(abspaths("resources/lexer/token_retrieval/typed_tokens.jlex"))

      returned_tokens = retrieve_tokens_from_lexer(lexer)
      @test returned_tokens == [
        LexerTokenDefinition(:Five, [(name=:value, type=:Float64, value="5.0")]),
        LexerTokenDefinition(
          :OneTwoThree,
          [
            (name=:value1, type=:Int, value="1"),
            (name=:value2, type=:Float32, value="2"),
            (name=:value3, type=:Int16, value="3")
          ]
        ),
        LexerTokenDefinition(:Digit, [(name=:value, type=:Int, value=raw"$$")]),
        LexerTokenDefinition(:Function, [(name=:value, type=:String, value=raw"func($$)")]),
        LexerTokenDefinition(:Message, [(name=:value, type=:String, value=raw"$$")]),
        LexerTokenDefinition(:Error, [])
      ]
    end

    @testset "Tokens with typing and naming" begin
      lexer = read_lexer_definition_file(abspaths("resources/lexer/token_retrieval/typed_named_tokens.jlex"))

      returned_tokens = retrieve_tokens_from_lexer(lexer)
      @test returned_tokens == [
        LexerTokenDefinition(:Five, [(name=:five, type=:Float64, value="5.0")]),
        LexerTokenDefinition(
          :OneTwoThree,
          [
            (name=:one, type=:Int, value="1"),
            (name=:two, type=:Float32, value="2"),
            (name=:three, type=:Int16, value="3")
          ]
        ),
        LexerTokenDefinition(:Digit, [(name=:value, type=:Int, value=raw"$$")]),
        LexerTokenDefinition(:Function, [(name=:func_call, type=:String, value=raw"func($$)")]),
        LexerTokenDefinition(:Message, [(name=:msg, type=:String, value=raw"$$")]),
        LexerTokenDefinition(:Error, [])
      ]
    end

    @testset "All tokens" begin
      lexer = read_lexer_definition_file(abspaths("resources/lexer/token_retrieval/all_tokens.jlex"))

      returned_tokens = retrieve_tokens_from_lexer(lexer)
      @test returned_tokens == [
        LexerTokenDefinition(:Digit, [(name=:value, type=:String, value=raw"$$")]),
        LexerTokenDefinition(:Number, [(name=:value, type=:Int, value=raw"$$")]),
        LexerTokenDefinition(
          :Identifier,
          [
            (name=:name, type=:String, value=raw"$$"),
            (name=:line, type=:Int, value="15")
          ]
        ),
        LexerTokenDefinition(:Error, [(name=:match, type=:String, value=raw"$$")])
      ]
    end
  end
end
