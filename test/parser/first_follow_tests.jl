@testset "First / follow sets" begin
  @testset "Throws errors for invalid grammars" begin
  end

  @testset "Correctly computes first set for given grammar" begin
    @testset "Left-recusrive grammar 1" begin
      parser = read_parser_definition_file(abspaths("resources/parser/first_follow/left_recursive_1.jpar"))

      terminals, nonterminals = parser.terminals, parser.nonterminals
      productions = parser.productions

      firsts = first_sets(
        terminals,
        nonterminals,
        productions,
      )
      @test firsts == Dict(
        :s => Set(:Y),
        :x => Set(:X),
        :y => Set(:Y),
        :X => Set(:X),
        :Y => Set(:Y)
      )
    end

    @testset "Left-recusrive grammar 2" begin
      parser = read_parser_definition_file(abspaths("resources/parser/first_follow/left_recursive_2.jpar"))

      terminals, nonterminals = parser.terminals, parser.nonterminals
      productions = parser.productions

      firsts = first_sets(
        terminals,
        nonterminals,
        productions,
      )
      @test firsts == Dict(
        :s => Set(EMPTY_SYMBOL, :X, :Y),
        :x => Set(EMPTY_SYMBOL, :X),
        :y => Set(EMPTY_SYMBOL, :Y),
        :X => Set(:X),
        :Y => Set(:Y)
      )
    end

    @testset "Dragonbook top-down parser grammar (4.28, p. 217)" begin
      parser = read_parser_definition_file(abspaths("resources/parser/definition_reader/dragonbook_4_28_ll.jpar"))

      terminals, nonterminals = parser.terminals, parser.nonterminals
      productions = parser.productions

      firsts = first_sets(
        terminals,
        nonterminals,
        productions,
      )
      @test firsts == Dict(
        Dict(
          :e => Set(:LPAREN, :ID),
          :e_prim => Set(:PLUS, EMPTY_SYMBOL),
          :t => Set(:LPAREN, :ID),
          :t_prim => Set(:TIMES, EMPTY_SYMBOL),
          :f => Set(:LPAREN, :ID),
          :LPAREN => Set(:LPAREN),
          :RPAREN => Set(:RPAREN),
          :ID => Set(:ID),
          :PLUS => Set(:PLUS),
          :TIMES => Set(:TIMES),
        ),
      )
    end

    @testset "All tokens in rhs are nullable" begin
      parser = read_parser_definition_file(abspaths("resources/parser/first_follow/all_nullable.jpar"))

      terminals, nonterminals = parser.terminals, parser.nonterminals
      productions = parser.productions

      firsts = first_sets(
        terminals,
        nonterminals,
        productions,
      )
      @test firsts == Dict(
        :s => Set(EMPTY_SYMBOL, :A, :B, :C),
        :a => Set(EMPTY_SYMBOL, :A),
        :b => Set(EMPTY_SYMBOL, :B),
        :c => Set(EMPTY_SYMBOL, :C),
        :A => Set(:A),
        :B => Set(:B),
        :C => Set(:C)
      )
    end

    @testset "All tokens in rhs are nullable (left recursion)" begin
      parser = read_parser_definition_file(abspaths("resources/parser/first_follow/all_nullable_left_recursion.jpar"))

      terminals, nonterminals = parser.terminals, parser.nonterminals
      productions = parser.productions

      firsts = first_sets(
        terminals,
        nonterminals,
        productions,
      )
      @test firsts == Dict(
        :s => Set(EMPTY_SYMBOL, :A, :B, :C),
        :a => Set(EMPTY_SYMBOL, :A),
        :b => Set(EMPTY_SYMBOL, :B),
        :c => Set(EMPTY_SYMBOL, :C),
        :A => Set(:A),
        :B => Set(:B),
        :C => Set(:C),
      )
    end
  end

  @testset "Correctly computes follow set for given grammar" begin

    @testset "Left-recusrive grammar 1" begin
      parser = read_parser_definition_file(abspaths("resources/parser/first_follow/left_recursive_1.jpar"))

      terminals, nonterminals = parser.terminals, parser.nonterminals
      productions = parser.productions

      firsts = first_sets(
        terminals,
        nonterminals,
        productions,
      )
      follows = follow_sets(
        firsts,
        terminals,
        nonterminals,
        productions,
        parser.starting
      )
      @test follows == Dict(
        :s => Set(END_OF_INPUT, :X),
        :x => Set(END_OF_INPUT, :X),
        :y => Set(END_OF_INPUT, :X)
      )
    end

    @testset "Left-recusrive grammar 2" begin
      parser = read_parser_definition_file(abspaths("resources/parser/first_follow/left_recursive_2.jpar"))

      terminals, nonterminals = parser.terminals, parser.nonterminals
      productions = parser.productions

      firsts = first_sets(
        terminals,
        nonterminals,
        productions,
      )
      follows = follow_sets(
        firsts,
        terminals,
        nonterminals,
        productions,
        parser.starting
      )
      @test follows == Dict(
        :s => Set(END_OF_INPUT, :X),
        :x => Set(END_OF_INPUT, :X),
        :y => Set(END_OF_INPUT, :X)
      )
    end

    @testset "Dragonbook top-down parser grammar (4.28, p. 217)" begin
      parser = read_parser_definition_file(abspaths("resources/parser/definition_reader/dragonbook_4_28_ll.jpar"))

      terminals, nonterminals = parser.terminals, parser.nonterminals
      productions = parser.productions

      firsts = first_sets(
        terminals,
        nonterminals,
        productions,
      )
      follows = follow_sets(
        firsts,
        terminals,
        nonterminals,
        productions,
        parser.starting
      )
      @test follows == Dict(
        :e => Set(:RPAREN, END_OF_INPUT),
        :e_prim => Set(:RPAREN, END_OF_INPUT),
        :t => Set(:PLUS, :RPAREN, END_OF_INPUT),
        :t_prim => Set(:PLUS, :RPAREN, END_OF_INPUT),
        :f => Set(:PLUS, :TIMES, :RPAREN, END_OF_INPUT)
      )
    end

    @testset "All tokens in rhs are nullable" begin
      parser = read_parser_definition_file(abspaths("resources/parser/first_follow/all_nullable.jpar"))

      terminals, nonterminals = parser.terminals, parser.nonterminals
      productions = parser.productions

      firsts = first_sets(
        terminals,
        nonterminals,
        productions,
      )
      follows = follow_sets(
        firsts,
        terminals,
        nonterminals,
        productions,
        parser.starting
      )
      @test follows == Dict(
        :s => Set(END_OF_INPUT),
        :a => Set(END_OF_INPUT, :B, :C),
        :b => Set(END_OF_INPUT, :C),
        :c => Set(END_OF_INPUT)
      )
    end

    @testset "All tokens in rhs are nullable (left recursion)" begin
      parser = read_parser_definition_file(abspaths("resources/parser/first_follow/all_nullable_left_recursion.jpar"))

      terminals, nonterminals = parser.terminals, parser.nonterminals
      productions = parser.productions

      firsts = first_sets(
        terminals,
        nonterminals,
        productions,
      )
      follows = follow_sets(
        firsts,
        terminals,
        nonterminals,
        productions,
        parser.starting
      )
      @test follows == Dict(
        :s => Set(END_OF_INPUT),
        :a => Set(END_OF_INPUT, :A, :B, :C),
        :b => Set(END_OF_INPUT, :B, :C),
        :c => Set(END_OF_INPUT, :C)
      )
    end
  end
end
