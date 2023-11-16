@testset "Special replacements in generated lexers" begin
  @testset "Throws errors for lexer files" begin

  end

  @testset "Full function pattern matches full functions correctly" begin
    @test match(full_function_pattern("at_end"), """
      function at_end()
        return __LEX__.current_match == ""
      end
    """) !== nothing
    @test match(full_function_pattern("test"), """
      function test() return 1 end
    """) !== nothing
    @test match(full_function_pattern("test"), """
      function test(
        a::Int=1,
        b,
        c
      )



      return 1
      end
    """) !== nothing
  end

  @testset "Full function pattern should not match one-liners" begin
    match(full_function_pattern("at_end"), """
      at_end() = __LEX__.current_match == ""
    """) === nothing
  end

  @testset "Correctly replaces special variables" begin
    @testset "Empty string" begin
      @test replace_special_variables_in_generated_lexer("") == ""
    end

    @testset "Dollar variables" begin
      @test replace_special_variables_in_generated_lexer(raw"""
      function test()
        return $$
      end
      """) == raw"""
      function test()
        return __LEX__current_match()
      end
      """
    end
  end

  @testset "Correctly replaces overloaded functions in generated code" begin
    @testset "Empty string" begin
      @test replace_overloaded_functions_in_generated_lexer(raw"""
      function __LEX__at_end()
        return getfield(__LEX__, :current_match) == ""
      end

      function __LEX__at_end()
        error("I overloaded it!")
      end
      """) == raw"""function __LEX__at_end()
        error("I overloaded it!")
      end
      """
    end
  end
end