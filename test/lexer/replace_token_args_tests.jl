@testset "Replacing returned tokens' arguments for special kwargs" begin
  @testset "Throws errors for invalid tokens returned in lexer actions" begin

  end

  @testset "Correctly retrieves tokens from actions" begin
    @testset "Empty actions" begin
      lexer = read_definition_file(from_current_path("resources/lexer/definition_reader/empty_sections.jlex"))

      returned_tokens = retrieve_tokens_from_lexer(lexer)
      lexer = replace_token_args_in_lexer(lexer, returned_tokens)
      @test lexer.actions == []
    end

    @testset "Tokens without typing and naming" begin
      lexer = read_definition_file(from_current_path("resources/lexer/token_retrieval/simple_tokens.jlex"))

      returned_tokens = retrieve_tokens_from_lexer(lexer)
      lexer = replace_token_args_in_lexer(lexer, returned_tokens)
      @test lexer.actions == [
        Action("\"5\"", " return Five(;value::String=convert_type(::String, 5)) "),
        Action("\"123\"", " return OneTwoThree(;value1::String=convert_type(::String, 1), value2::String=convert_type(::String, 2), value3::String=convert_type(::String, 3)) "),
        Action("[0-9]", raw" return Digit(;value::String=convert_type(::String, $$)) "),
        Action("\"def\"", raw" return Function(;value::String=convert_type(::String, func($$))) "),
        Action(".*", " return Error() ")
      ]
    end

    @testset "Tokens with typing, without naming" begin
      lexer = read_definition_file(from_current_path("resources/lexer/token_retrieval/typed_tokens.jlex"))

      returned_tokens = retrieve_tokens_from_lexer(lexer)
      lexer = replace_token_args_in_lexer(lexer, returned_tokens)
      @test lexer.actions == [
        Action("\"5.0\"", " return Five(;value::Float64=convert_type(::Float64, 5.0)) "),
        Action("\"123\"", " return OneTwoThree(;value1::Int=convert_type(::Int, 1), value2::Float32=convert_type(::Float32, 2), value3::Int16=convert_type(::Int16, 3)) "),
        Action("[0-9]", raw" return Digit(;value::Int=convert_type(::Int, $$)) "),
        Action("\"def\"", raw" return Function(;value::String=convert_type(::String, func($$))) "),
        Action("[a-zA-Z]+", raw" return Message(;value::String=convert_type(::String, $$)) "),
        Action(".*", " return Error() ")
      ]
    end

    @testset "Tokens with typing and naming" begin
      lexer = read_definition_file(from_current_path("resources/lexer/token_retrieval/typed_named_tokens.jlex"))

      returned_tokens = retrieve_tokens_from_lexer(lexer)
      lexer = replace_token_args_in_lexer(lexer, returned_tokens)
      @test lexer.actions == [
        Action("\"5.0\"", " return Five(;five::Float64=convert_type(::Float64, 5.0)) "),
        Action("\"123\"", " return OneTwoThree(;one::Int=convert_type(::Int, 1), two::Float32=convert_type(::Float32, 2), three::Int16=convert_type(::Int16, 3)) "),
        Action("[0-9]", raw" return Digit(;value::Int=convert_type(::Int, $$)) "),
        Action("\"def\"", raw" return Function(;func_call::String=convert_type(::String, func($$))) "),
        Action("[a-zA-Z]+", raw" return Message(;msg::String=convert_type(::String, $$)) "),
        Action(".*", " return Error() ")
      ]
    end

    @testset "All tokens" begin
      lexer = read_definition_file(from_current_path("resources/lexer/token_retrieval/all_tokens.jlex"))

      returned_tokens = retrieve_tokens_from_lexer(lexer)
      lexer = replace_token_args_in_lexer(lexer, returned_tokens)
      @test lexer.actions == [
        Action("\"invalid return\"", " return Omitted "),
        Action("\"missing parenthesis\"", " return Omitted( "),
        Action("[0-9]", raw" return Digit(;value::String=convert_type(::String, $$)) "),
        Action("[0-9]+", raw" return Number(;value::Int=convert_type(::Int, $$)) "),
        Action("[_a-zA-Z][_a-zA-Z0-9]*", raw" return Identifier(;name::String=convert_type(::String, $$), line::Int=convert_type(::Int, 15)) "),
        Action(".*", raw" return Error(;match::String=convert_type(::String, $$)) ")
      ]
    end
  end
end