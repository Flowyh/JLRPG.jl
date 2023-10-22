@testset "Token retrevial from lexer actions" begin
  @testset "Throws errors for invalid tokens returned in lexer actions" begin
    
  end

  @testset "Correctly retrieves tokens from actions" begin
    @testset "Empty actions" begin
      lexer = read_definition_file(from_current_path("resources/lexer/definition_reader/empty_sections.jlex"))

      returned_tokens = retrieve_tokens_from_lexer(lexer)
      @test returned_tokens == []
    end

    @testset "Tokens without typing and naming" begin
      lexer = read_definition_file(from_current_path("resources/lexer/token_retrieval/simple_tokens.jlex"))

      returned_tokens = retrieve_tokens_from_lexer(lexer)

      @test returned_tokens == [
        TokenDefinition(:Five, Dict(:value => (:String, "5"))),
        TokenDefinition(
          :OneTwoThree,
          Dict(
            :value1 => (:String, "1"),
            :value2 => (:String, "2"),
            :value3 => (:String, "3")
          )
        ),
        TokenDefinition(:Digit, Dict(:value => (:String, raw"$$"))),
        TokenDefinition(:Function, Dict(:value => (:String, raw"func($$)"))),
        TokenDefinition(:Error, Dict())
      ]
    end

    @testset "Tokens with typing, without naming" begin
      lexer = read_definition_file(from_current_path("resources/lexer/token_retrieval/typed_tokens.jlex"))

      returned_tokens = retrieve_tokens_from_lexer(lexer)

      @test returned_tokens == [
        TokenDefinition(:Five, Dict(:value => (:Float64, "5.0"))),
        TokenDefinition(
          :OneTwoThree,
          Dict(
            :value1 => (:Int, "1"),
            :value2 => (:Float32, "2"),
            :value3 => (:Int16, "3")
          )
        ),
        TokenDefinition(:Digit, Dict(:value => (:Int, raw"$$"))),
        TokenDefinition(:Function, Dict(:value => (:String, raw"func($$)"))),
        TokenDefinition(:Message, Dict(:value => (:String, raw"$$"))),
        TokenDefinition(:Error, Dict())
      ]
    end

    @testset "Tokens with typing and naming" begin
      lexer = read_definition_file(from_current_path("resources/lexer/token_retrieval/typed_named_tokens.jlex"))

      returned_tokens = retrieve_tokens_from_lexer(lexer)

      @test returned_tokens == [
        TokenDefinition(:Five, Dict(:five => (:Float64, "5.0"))),
        TokenDefinition(
          :OneTwoThree,
          Dict(
            :one => (:Int, "1"),
            :two => (:Float32, "2"),
            :three => (:Int16, "3")
          )
        ),
        TokenDefinition(:Digit, Dict(:value => (:Int, raw"$$"))),
        TokenDefinition(:Function, Dict(:func_call => (:String, raw"func($$)"))),
        TokenDefinition(:Message, Dict(:msg => (:String, raw"$$"))),
        TokenDefinition(:Error, Dict())
      ]
    end

    @testset "All tokens" begin
      lexer = read_definition_file(from_current_path("resources/lexer/token_retrieval/all_tokens.jlex"))

      returned_tokens = retrieve_tokens_from_lexer(lexer)

      @test returned_tokens == [
        TokenDefinition(:Digit, Dict(:value => (:String, raw"$$"))),
        TokenDefinition(:Number, Dict(:value => (:Int, raw"$$"))),
        TokenDefinition(
          :Identifier, 
          Dict(
            :name => (:String, raw"$$"),
            :line => (:Int, "15")
          )
        ),
        TokenDefinition(:Error, Dict((:match => (:String, raw"$$"))))
      ] 
    end
  end
end
