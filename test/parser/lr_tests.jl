@testset "LR(1) LR" begin
  @testset "Throws errors for invalid grammars" begin
    @testset "No augmented start for computing LR(1) items" begin
      productions::Dict{Symbol, Vector{ParserProduction}} = Dict(
        :e => [
          ParserProduction(:e, [:e, :PLUS, :t]),
          ParserProduction(:e, [:t])
        ],
        :t => [
          ParserProduction(:t, [:t, :TIMES, :f]),
          ParserProduction(:t, [:f])
        ],
        :f => [
          ParserProduction(:f, [:LPAREN, :e, :RPAREN]),
          ParserProduction(:f, [:ID])
        ]
      )
      terminals::Vector{Symbol} = [:PLUS, :TIMES, :LPAREN, :RPAREN, :ID, END_OF_INPUT]
      nonterminals::Vector{Symbol} = [:e, :t, :f]
      grammar_symbols::Vector{Symbol} = [:e, :t, :f, :PLUS, :TIMES, :LPAREN, :RPAREN, :ID, END_OF_INPUT]

      firsts = first_sets(
        terminals,
        nonterminals,
        productions,
      )

      @test_throws "Parser must have an augmented start production" lr1_items(
        productions,
        nonterminals,
        grammar_symbols,
        firsts
      )
    end
  end

  @testset "Correctly computes closure for given items" begin
    @testset "Empty items" begin
      productions::Dict{Symbol, Vector{ParserProduction}} = Dict()
      nonterminals::Vector{Symbol} = []
      firsts::Dict{Symbol, Set{Symbol}} = Dict()

      closure::Vector{ParsingItem} = lr1_closure(
        Vector{ParsingItem}(),
        productions,
        nonterminals,
        firsts
      )

      @test closure == []
    end

    @testset "Dragonbook example (4.54, p. 263)" begin
      productions::Dict{Symbol, Vector{ParserProduction}} = Dict(
        AUGMENTED_START => [
          ParserProduction(AUGMENTED_START, [:s])
        ],
        :s => [
          ParserProduction(:s, [:c, :c]),
        ],
        :c => [
          ParserProduction(:c, [:C, :c]),
          ParserProduction(:c, [:D])
        ],
      )
      terminals::Vector{Symbol} = [:C, :D, END_OF_INPUT]
      nonterminals::Vector{Symbol} = [:s, :c]

      firsts = first_sets(
        terminals,
        nonterminals,
        productions,
      )

      closure::Vector{ParsingItem} = lr1_closure(
        [ParsingItem(AUGMENTED_START, 1; lookahead=END_OF_INPUT)],
        productions,
        nonterminals,
        firsts
      )

      @test closure == [
        ParsingItem(AUGMENTED_START, 1; lookahead=END_OF_INPUT),
        ParsingItem(:s, 1; lookahead=END_OF_INPUT),
        ParsingItem(:c, 1; lookahead=:D),
        ParsingItem(:c, 2; lookahead=:D),
        ParsingItem(:c, 1; lookahead=:C),
        ParsingItem(:c, 2; lookahead=:C),
      ]
    end

    @testset "No closure items added" begin
      productions::Dict{Symbol, Vector{ParserProduction}} = Dict(
        AUGMENTED_START => [
          ParserProduction(AUGMENTED_START, [:s])
        ],
        :s => [
          ParserProduction(:s, [:c, :c]),
        ],
        :c => [
          ParserProduction(:c, [:C, :c]),
          ParserProduction(:c, [:D])
        ],
      )
      terminals::Vector{Symbol} = [:C, :D, END_OF_INPUT]
      nonterminals::Vector{Symbol} = [:s, :c]

      firsts = first_sets(
        terminals,
        nonterminals,
        productions,
      )

      closure::Vector{ParsingItem} = lr1_closure(
        [ParsingItem(:c, 1; dot=0, lookahead=END_OF_INPUT)],
        productions,
        nonterminals,
        firsts
      )

      @test closure == [ParsingItem(:c, 1; dot=0, lookahead=END_OF_INPUT)]
    end
  end

  @testset "Correctly computes goto for given items" begin
    @testset "Empty items" begin
      productions::Dict{Symbol, Vector{ParserProduction}} = Dict()
      nonterminals::Vector{Symbol} = []
      firsts::Dict{Symbol, Set{Symbol}} = Dict()

      goto::Vector{ParsingItem} = lr1_goto(
        Vector{ParsingItem}(),
        :nothing,
        productions,
        nonterminals,
        firsts
      )

      @test goto == []
    end

    @testset "Dragonbook example (4.54, p. 263)" begin
      productions::Dict{Symbol, Vector{ParserProduction}} = Dict(
        AUGMENTED_START => [
          ParserProduction(AUGMENTED_START, [:s])
        ],
        :s => [
          ParserProduction(:s, [:c, :c]),
        ],
        :c => [
          ParserProduction(:c, [:C, :c]),
          ParserProduction(:c, [:D])
        ],
      )
      terminals::Vector{Symbol} = [:C, :D, END_OF_INPUT]
      nonterminals::Vector{Symbol} = [:s, :c]

      firsts = first_sets(
        terminals,
        nonterminals,
        productions,
      )

      goto::Vector{ParsingItem} = lr1_goto(
        [ # I0
          ParsingItem(AUGMENTED_START, 1; lookahead=END_OF_INPUT),
          ParsingItem(:s, 1; lookahead=END_OF_INPUT),
          ParsingItem(:c, 1; lookahead=:D),
          ParsingItem(:c, 2; lookahead=:D),
          ParsingItem(:c, 1; lookahead=:C),
          ParsingItem(:c, 2; lookahead=:C),
        ],
        :c,
        productions,
        nonterminals,
        firsts
      )

      @test goto == [
        ParsingItem(:s, 1; dot=1, lookahead=END_OF_INPUT),
        ParsingItem(:c, 1; lookahead=END_OF_INPUT),
        ParsingItem(:c, 2; lookahead=END_OF_INPUT)
      ]
    end

    @testset "No items to go over given symbol" begin
      productions::Dict{Symbol, Vector{ParserProduction}} = Dict(
        AUGMENTED_START => [
          ParserProduction(AUGMENTED_START, [:s])
        ],
        :s => [
          ParserProduction(:s, [:c, :c]),
        ],
        :c => [
          ParserProduction(:c, [:C, :c]),
          ParserProduction(:c, [:D])
        ],
      )
      terminals::Vector{Symbol} = [:C, :D, END_OF_INPUT]
      nonterminals::Vector{Symbol} = [:s, :c]

      firsts = first_sets(
        terminals,
        nonterminals,
        productions,
      )

      goto::Vector{ParsingItem} = lr1_goto(
        [ # I2
          ParsingItem(:s, 1; dot=1, lookahead=END_OF_INPUT),
          ParsingItem(:c, 1; lookahead=END_OF_INPUT),
          ParsingItem(:c, 2; lookahead=END_OF_INPUT)
        ],
        :s,
        productions,
        nonterminals,
        firsts
      )

      @test goto == []
    end
  end

  @testset "Correctly computes all lr0 items" begin
    @testset "Dragonbook example (4.54, p. 263-264)" begin
      productions::Dict{Symbol, Vector{ParserProduction}} = Dict(
        AUGMENTED_START => [
          ParserProduction(AUGMENTED_START, [:s])
        ],
        :s => [
          ParserProduction(:s, [:c, :c]),
        ],
        :c => [
          ParserProduction(:c, [:C, :c]),
          ParserProduction(:c, [:D])
        ],
      )
      terminals::Vector{Symbol} = [:C, :D, END_OF_INPUT]
      nonterminals::Vector{Symbol} = [:s, :c]
      grammar_symbols::Vector{Symbol} = [:s, :c, :C, :D, END_OF_INPUT]

      firsts = first_sets(
        terminals,
        nonterminals,
        productions,
      )

      items::Vector{Vector{ParsingItem}}, gotos::Dict{Int, Dict{Symbol, Int}} = lr1_items(
        productions,
        nonterminals,
        grammar_symbols,
        firsts
      )

      @test items == [
        [ # I0
          ParsingItem(AUGMENTED_START, 1; lookahead=END_OF_INPUT),
          ParsingItem(:s, 1; lookahead=END_OF_INPUT),
          ParsingItem(:c, 1; lookahead=:D),
          ParsingItem(:c, 2; lookahead=:D),
          ParsingItem(:c, 1; lookahead=:C),
          ParsingItem(:c, 2; lookahead=:C)
        ],
        [ # I1
          ParsingItem(AUGMENTED_START, 1; dot=1, lookahead=END_OF_INPUT)
        ],
        [ # I2
          ParsingItem(:s, 1; dot=1, lookahead=END_OF_INPUT),
          ParsingItem(:c, 1; lookahead=END_OF_INPUT),
          ParsingItem(:c, 2; lookahead=END_OF_INPUT)
        ],
        [ # I3
          ParsingItem(:c, 1; dot=1, lookahead=:D),
          ParsingItem(:c, 1; dot=1, lookahead=:C),
          ParsingItem(:c, 1; lookahead=:D),
          ParsingItem(:c, 2; lookahead=:D),
          ParsingItem(:c, 1; lookahead=:C),
          ParsingItem(:c, 2; lookahead=:C)
        ],
        [ # I4
          ParsingItem(:c, 2; dot=1, lookahead=:D),
          ParsingItem(:c, 2; dot=1, lookahead=:C),
        ],
        [ # I5
          ParsingItem(:s, 1; dot=2, lookahead=END_OF_INPUT),
        ],
        [ # I6
          ParsingItem(:c, 1; dot=1, lookahead=END_OF_INPUT),
          ParsingItem(:c, 1; lookahead=END_OF_INPUT),
          ParsingItem(:c, 2; lookahead=END_OF_INPUT)
        ],
        [ # I7
          ParsingItem(:c, 2; dot=1, lookahead=END_OF_INPUT)
        ],
        [ # I8
          ParsingItem(:c, 1; dot=2, lookahead=:D),
          ParsingItem(:c, 1; dot=2, lookahead=:C)
        ],
        [ # I9
          ParsingItem(:c, 1; dot=2, lookahead=END_OF_INPUT)
        ],
      ]

      @test gotos == Dict(
        0 => Dict(
          :s => 1,
          :c => 2,
          :C => 3,
          :D => 4
        ),
        2 => Dict(
          :c => 5,
          :C => 6,
          :D => 7
        ),
        3 => Dict(
          :c => 8,
          :C => 3,
          :D => 4
        ),
        6 => Dict(
          :c => 9,
          :C => 6,
          :D => 7
        )
      )
    end
  end

  @testset "Correctly computes LR(1) parsing tables for LR(1) grammars" begin
    parser::Parser = read_parser_definition_file(abspaths("resources/parser/lr/dragonbook_4_57_lr1.jpar"))
    augmented_parser = augment_parser(parser)

    table::ParsingTable = LrParsingTable(augmented_parser)

    @test table == ParsingTable(
      Dict{Int, Dict{Symbol, ParsingTableAction}}(
        0 => Dict(
          :C => Shift(3),
          :D => Shift(4)
        ),
        1 => Dict(
          END_OF_INPUT => Accept()
        ),
        2 => Dict(
          :C => Shift(6),
          :D => Shift(7)
        ),
        3 => Dict(
          :C => Shift(3),
          :D => Shift(4)
        ),
        4 => Dict(
          :C => Reduce(:c, 2),
          :D => Reduce(:c, 2)
        ),
        5 => Dict(
          END_OF_INPUT => Reduce(:s, 1)
        ),
        6 => Dict(
          :C => Shift(6),
          :D => Shift(7)
        ),
        7 => Dict(
          END_OF_INPUT => Reduce(:c, 2)
        ),
        8 => Dict(
          :C => Reduce(:c, 1),
          :D => Reduce(:c, 1)
        ),
        9 => Dict(
          END_OF_INPUT => Reduce(:c, 1)
        ),
      ),
      Dict{Int, Dict{Symbol, Int}}(
        0 => Dict(
          :s => 1,
          :c => 2
        ),
        2 => Dict(
          :c => 5
        ),
        3 => Dict(
          :c => 8
        ),
        6 => Dict(
          :c => 9
        )
      )
    )
  end
end
