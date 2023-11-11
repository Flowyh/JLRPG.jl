@testset "Definition files reader" begin
  @testset "Throws errors for invalid grammars" begin
  end

  @testset "Correctly computes first set for given grammar" begin
    @testset "Left-recusrive grammar 1" begin
      parser = read_parser_definition_file(from_current_path("resources/parser/first_follow/left_recursive_1.jpar"))

      firsts = first_sets(parser)
      @test firsts == Dict(
        :s => Set(:Y),
        :x => Set(:X),
        :y => Set(:Y)
      )
    end

    @testset "Left-recusrive grammar 2" begin
      parser = read_parser_definition_file(from_current_path("resources/parser/first_follow/left_recursive_2.jpar"))

      firsts = first_sets(parser)
      @test firsts == Dict(
        :s => Set(EMPTY_SYMBOL, :X, :Y),
        :x => Set(EMPTY_SYMBOL, :X),
        :y => Set(EMPTY_SYMBOL, :Y)
      )
    end

    @testset "Dragonbook top-down parser grammar (4.28, p. 217)" begin
      parser = read_parser_definition_file(from_current_path("resources/parser/definition_reader/dragonbook_4_28_ll.jpar"))

      firsts = first_sets(parser)
      @test firsts == Dict(
        Dict(
          :e => Set(:LPAREN, :ID),
          :e_prim => Set(:PLUS, EMPTY_SYMBOL),
          :t => Set(:LPAREN, :ID),
          :t_prim => Set(:TIMES, EMPTY_SYMBOL),
          :f => Set(:LPAREN, :ID)
        ),
      )
    end

    @testset "All tokens in rhs are nullable" begin
      parser = read_parser_definition_file(from_current_path("resources/parser/first_follow/all_nullable.jpar"))

      firsts = first_sets(parser)
      @test firsts == Dict(
        :s => Set(EMPTY_SYMBOL, :A, :B, :C),
        :a => Set(EMPTY_SYMBOL, :A),
        :b => Set(EMPTY_SYMBOL, :B),
        :c => Set(EMPTY_SYMBOL, :C)
      )
    end

    @testset "All tokens in rhs are nullable (left recursion)" begin
      parser = read_parser_definition_file(from_current_path("resources/parser/first_follow/all_nullable_left_recursion.jpar"))

      firsts = first_sets(parser)
      @test firsts == Dict(
        :s => Set(EMPTY_SYMBOL, :A, :B, :C),
        :a => Set(EMPTY_SYMBOL, :A),
        :b => Set(EMPTY_SYMBOL, :B),
        :c => Set(EMPTY_SYMBOL, :C)
      )
    end
  end

  @testset "Correctly computes follow set for given grammar" begin

    @testset "Left-recusrive grammar 1" begin
      parser = read_parser_definition_file(from_current_path("resources/parser/first_follow/left_recursive_1.jpar"))

      firsts = first_sets(parser)
      follows = follow_sets(firsts, parser)
      @test follows == Dict(
        :s => Set(END_OF_INPUT, :X),
        :x => Set(END_OF_INPUT, :X),
        :y => Set(END_OF_INPUT, :X)
      )
    end

    @testset "Left-recusrive grammar 2" begin
      parser = read_parser_definition_file(from_current_path("resources/parser/first_follow/left_recursive_2.jpar"))

      firsts = first_sets(parser)
      follows = follow_sets(firsts, parser)
      @test follows == Dict(
        :s => Set(END_OF_INPUT, :X),
        :x => Set(END_OF_INPUT, :X),
        :y => Set(END_OF_INPUT, :X)
      )
    end

    @testset "Dragonbook top-down parser grammar (4.28, p. 217)" begin
      parser = read_parser_definition_file(from_current_path("resources/parser/definition_reader/dragonbook_4_28_ll.jpar"))

      firsts = first_sets(parser)
      follows = follow_sets(firsts, parser)
      @test follows == Dict(
        :e => Set(:RPAREN, END_OF_INPUT),
        :e_prim => Set(:RPAREN, END_OF_INPUT),
        :t => Set(:PLUS, :RPAREN, END_OF_INPUT),
        :t_prim => Set(:PLUS, :RPAREN, END_OF_INPUT),
        :f => Set(:PLUS, :TIMES, :RPAREN, END_OF_INPUT)
      )
    end

    @testset "All tokens in rhs are nullable" begin
      parser = read_parser_definition_file(from_current_path("resources/parser/first_follow/all_nullable.jpar"))

      firsts = first_sets(parser)
      follows = follow_sets(firsts, parser)
      @test follows == Dict(
        :s => Set(END_OF_INPUT),
        :a => Set(END_OF_INPUT, :B, :C),
        :b => Set(END_OF_INPUT, :C),
        :c => Set(END_OF_INPUT)
      )
    end

    @testset "All tokens in rhs are nullable (left recursion)" begin
      parser = read_parser_definition_file(from_current_path("resources/parser/first_follow/all_nullable_left_recursion.jpar"))

      firsts = first_sets(parser)
      follows = follow_sets(firsts, parser)
      @test follows == Dict(
        :s => Set(END_OF_INPUT),
        :a => Set(END_OF_INPUT, :A, :B, :C),
        :b => Set(END_OF_INPUT, :B, :C),
        :c => Set(END_OF_INPUT, :C)
      )
    end
  end
end
