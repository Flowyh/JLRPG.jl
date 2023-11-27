@testset "Simple LR" begin
  @testset "Throws errors for invalid grammars" begin
    @testset "No augmented start for computing LR(0) items" begin
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
      nonterminals::Vector{Symbol} = [:e, :t, :f]
      grammar_symbols::Vector{Symbol} = [:e, :t, :f, :PLUS, :TIMES, :LPAREN, :RPAREN, :ID]

      @test_throws "Parser must have an augmented start production" lr0_items(
        productions,
        nonterminals,
        grammar_symbols
      )
    end
  end

  @testset "Correctly computes closure for given items" begin
    @testset "Empty items" begin
      productions::Dict{Symbol, Vector{ParserProduction}} = Dict()
      nonterminals::Vector{Symbol} = []

      closure::Vector{ParsingItem} = lr0_closure(
        Vector{ParsingItem}(),
        productions,
        nonterminals
      )

      @test closure == []
    end

    @testset "Dragonbook example (4.40, p. 244)" begin
      productions::Dict{Symbol, Vector{ParserProduction}} = Dict(
        AUGMENTED_START => [
          ParserProduction(AUGMENTED_START, [:e])
        ],
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
      nonterminals::Vector{Symbol} = [:e, :t, :f]

      closure::Vector{ParsingItem} = lr0_closure(
        [ParsingItem(AUGMENTED_START, 1)],
        productions,
        nonterminals
      )

      @test closure == [
        ParsingItem(AUGMENTED_START, 1),
        ParsingItem(:e, 1),
        ParsingItem(:e, 2),
        ParsingItem(:t, 1),
        ParsingItem(:t, 2),
        ParsingItem(:f, 1),
        ParsingItem(:f, 2),
      ]
    end

    @testset "No closure items added" begin
      productions::Dict{Symbol, Vector{ParserProduction}} = Dict(
        AUGMENTED_START => [
          ParserProduction(AUGMENTED_START, [:e])
        ],
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
      nonterminals::Vector{Symbol} = [:e, :t, :f]

      closure::Vector{ParsingItem} = lr0_closure(
        [ParsingItem(:e, 1; dot=1)],
        productions,
        nonterminals
      )

      @test closure == [ParsingItem(:e, 1; dot=1)]
    end
  end

  @testset "Correctly computes goto for given items" begin
    @testset "Empty items" begin
      productions::Dict{Symbol, Vector{ParserProduction}} = Dict()
      nonterminals::Vector{Symbol} = []

      goto::Vector{ParsingItem} = lr0_goto(
        Vector{ParsingItem}(),
        :nothing,
        productions,
        nonterminals
      )

      @test goto == []
    end

    @testset "Dragonbook example (4.41, p. 246)" begin
      productions::Dict{Symbol, Vector{ParserProduction}} = Dict(
        AUGMENTED_START => [
          ParserProduction(AUGMENTED_START, [:e])
        ],
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
      nonterminals::Vector{Symbol} = [:e, :t, :f]

      goto::Vector{ParsingItem} = lr0_goto(
        [
          ParsingItem(AUGMENTED_START, 1; dot=1),
          ParsingItem(:e, 1; dot=1)
        ],
        :PLUS,
        productions,
        nonterminals
      )

      @test goto == [
        ParsingItem(:e, 1; dot=2),
        ParsingItem(:t, 1),
        ParsingItem(:t, 2),
        ParsingItem(:f, 1),
        ParsingItem(:f, 2),
      ]
    end

    @testset "No items to go over given symbol" begin
      productions::Dict{Symbol, Vector{ParserProduction}} = Dict(
        AUGMENTED_START => [
          ParserProduction(AUGMENTED_START, [:e])
        ],
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
      nonterminals::Vector{Symbol} = [:e, :t, :f]

      goto::Vector{ParsingItem} = lr0_goto(
        [ParsingItem(:t, 1; dot=1)],
        :PLUS,
        productions,
        nonterminals
      )

      @test goto == []
    end
  end

  @testset "Correctly computes all lr0 items" begin
    @testset "Dragonbook example (4.42, p. 246 / f. 4.31, p. 2.44)" begin
      productions::Dict{Symbol, Vector{ParserProduction}} = Dict(
        AUGMENTED_START => [
          ParserProduction(AUGMENTED_START, [:e])
        ],
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
      nonterminals::Vector{Symbol} = [:e, :t, :f]
      grammar_symbols::Vector{Symbol} = [:e, :t, :f, :PLUS, :TIMES, :LPAREN, :RPAREN, :ID]

      items::Vector{Vector{ParsingItem}}, gotos::Dict{Int, Dict{Symbol, Int}} = lr0_items(
        productions,
        nonterminals,
        grammar_symbols
      )

      @test items == [
        [ # I0
          ParsingItem(AUGMENTED_START, 1),
          ParsingItem(:e, 1),
          ParsingItem(:e, 2),
          ParsingItem(:t, 1),
          ParsingItem(:t, 2),
          ParsingItem(:f, 1),
          ParsingItem(:f, 2),
        ],
        [ # I1
          ParsingItem(AUGMENTED_START, 1; dot=1),
          ParsingItem(:e, 1; dot=1)
        ],
        [ # I2
          ParsingItem(:e, 2; dot=1),
          ParsingItem(:t, 1; dot=1)
        ],
        [ # I3
          ParsingItem(:t, 2; dot=1)
        ],
        [ # I4
          ParsingItem(:f, 1; dot=1),
          ParsingItem(:e, 1),
          ParsingItem(:e, 2),
          ParsingItem(:t, 1),
          ParsingItem(:t, 2),
          ParsingItem(:f, 1),
          ParsingItem(:f, 2),
        ],
        [ # I5
          ParsingItem(:f, 2; dot=1)
        ],
        [ # I6
          ParsingItem(:e, 1; dot=2),
          ParsingItem(:t, 1),
          ParsingItem(:t, 2),
          ParsingItem(:f, 1),
          ParsingItem(:f, 2),
        ],
        [ # I7
          ParsingItem(:t, 1; dot=2),
          ParsingItem(:f, 1),
          ParsingItem(:f, 2),
        ],
        [ # I8
          ParsingItem(:f, 1; dot=2),
          ParsingItem(:e, 1; dot=1),
        ],
        [ # I9
          ParsingItem(:e, 1; dot=3),
          ParsingItem(:t, 1; dot=1)
        ],
        [ # I10
          ParsingItem(:t, 1; dot=3)
        ],
        [ # I11
          ParsingItem(:f, 1; dot=3)
        ]
      ]

      @test gotos == Dict(
        0 => Dict(
          :e => 1,
          :t => 2,
          :ID => 5,
          :LPAREN => 4,
          :f => 3
        ),
        1 => Dict(
          :PLUS => 6
        ),
        2 => Dict(
          :TIMES => 7
        ),
        4 => Dict(
          :e => 8,
          :LPAREN => 4,
          :t => 2,
          :f => 3,
          :ID => 5
        ),
        6 => Dict(
          :t => 9,
          :f => 3,
          :LPAREN => 4,
          :ID => 5
        ),
        7 => Dict(
          :f => 10,
          :LPAREN => 4,
          :ID => 5
        ),
        8 => Dict(
          :PLUS => 6,
          :RPAREN => 11
        ),
        9 => Dict(
          :TIMES => 7
        )
      )
    end
  end

  @testset "Correctly computes SLR parsing tables for SLR grammars" begin
    parser::Parser = read_parser_definition_file(abspaths("resources/parser/slr/dragonbook_4_45_slr.jpar"))
    augmented_parser = augment_parser(parser)

    table::ParsingTable = SlrParsingTable(augmented_parser)

    @test table == ParsingTable(
      Dict{Int, Dict{Symbol, ParsingTableAction}}(
        0 => Dict(
          :ID => Shift(5),
          :LPAREN => Shift(4)
        ),
        1 => Dict(
          :PLUS => Shift(6),
          END_OF_INPUT => Accept()
        ),
        2 => Dict(
          :PLUS => Reduce(:e, 2),
          :TIMES => Shift(7),
          :RPAREN => Reduce(:e, 2),
          END_OF_INPUT => Reduce(:e, 2)
        ),
        3 => Dict(
          :PLUS => Reduce(:t, 2),
          :TIMES => Reduce(:t, 2),
          :RPAREN => Reduce(:t, 2),
          END_OF_INPUT => Reduce(:t, 2)
        ),
        4 => Dict(
          :ID => Shift(5),
          :LPAREN => Shift(4)
        ),
        5 => Dict(
          :PLUS => Reduce(:f, 2),
          :TIMES => Reduce(:f, 2),
          :RPAREN => Reduce(:f, 2),
          END_OF_INPUT => Reduce(:f, 2)
        ),
        6 => Dict(
          :ID => Shift(5),
          :LPAREN => Shift(4)
        ),
        7 => Dict(
          :ID => Shift(5),
          :LPAREN => Shift(4)
        ),
        8 => Dict(
          :PLUS => Shift(6),
          :RPAREN => Shift(11)
        ),
        9 => Dict(
          :PLUS => Reduce(:e, 1),
          :TIMES => Shift(7),
          :RPAREN => Reduce(:e, 1),
          END_OF_INPUT => Reduce(:e, 1)
        ),
        10 => Dict(
          :PLUS => Reduce(:t, 1),
          :TIMES => Reduce(:t, 1),
          :RPAREN => Reduce(:t, 1),
          END_OF_INPUT => Reduce(:t, 1)
        ),
        11 => Dict(
          :PLUS => Reduce(:f, 1),
          :TIMES => Reduce(:f, 1),
          :RPAREN => Reduce(:f, 1),
          END_OF_INPUT => Reduce(:f, 1)
        )
      ),
      Dict{Int, Dict{Symbol, Int}}(
        0 => Dict(
          :e => 1,
          :t => 2,
          :f => 3
        ),
        4 => Dict(
          :e => 8,
          :t => 2,
          :f => 3
        ),
        6 => Dict(
          :t => 9,
          :f => 3
        ),
        7 => Dict(
          :f => 10
        )
      )
    )
  end
end
