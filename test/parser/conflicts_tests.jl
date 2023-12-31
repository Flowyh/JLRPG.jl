@testset "Generating parser with conflicts" begin
  @testset "Dragonbook 4.48 (SLR)" begin
    path = abspaths("resources/parser/ambiguous/dragonbook_4_48_slr.jpar")
    error_msg = "Conflict in parsing table. Shift-Reduce conflict at state 2, symbol EQUALS"
    @test_throws error_msg generate_parser(path)
  end

  @testset "Ambiguous if else" begin
    path = abspaths("resources/parser/ambiguous/if_else.jpar")
    error_msg = "Conflict in parsing table. Shift-Reduce conflict at state 7, symbol ELSE." *
                "\nCurrent action Reduce(:stmt, 1), new action: Shift(8)."
    @test_throws error_msg generate_parser(path)
  end

  @testset "Dragonbook ex. 4.6.9 (SLR)" begin
    path = abspaths("resources/parser/ambiguous/dragonbook_ex_4_6_9_slr.jpar")
    error_msg = "Conflict in parsing table. Shift-Reduce conflict at state 6, symbol B." *
                "\nCurrent action Reduce(:a, 1), new action: Shift(4)."
    @test_throws error_msg generate_parser(path)
  end
end
