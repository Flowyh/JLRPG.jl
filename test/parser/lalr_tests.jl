@testset "LALR(1)" begin
  @testset "Correctly computes LALR(1) parsing tables for LALR(1) grammars" begin
    parser::Parser = read_parser_definition_file(abspaths("resources/parser/lr/dragonbook_4_57_lr1.jpar"))
    augmented_parser = augment_parser(parser)

    table::ParsingTable = LalrParsingTable(augmented_parser)

    @test table == ParsingTable(
      Dict{Int, Dict{Symbol, ParsingTableAction}}(
        0 => Dict(
          :C => Shift(3), # 36
          :D => Shift(4)  # 47
        ),
        1 => Dict(
          END_OF_INPUT => Accept()
        ),
        2 => Dict(
          :C => Shift(3), # 36
          :D => Shift(4)  # 47
        ),
        3 => Dict(
          :C => Shift(3), # 36
          :D => Shift(4)  # 47
        ),
        4 => Dict(
          :C => Reduce(:c, 2),
          :D => Reduce(:c, 2),
          END_OF_INPUT => Reduce(:c, 2)
        ),
        5 => Dict(
          END_OF_INPUT => Reduce(:s, 1)
        ),
        6 => Dict(
          :C => Reduce(:c, 1),
          :D => Reduce(:c, 1),
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
          :c => 6
        )
      )
    )
  end
end
