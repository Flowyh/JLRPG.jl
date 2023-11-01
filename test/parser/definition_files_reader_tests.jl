@testset "Definition files reader" begin
  @testset "Throws errors for invalid definition files" begin
    @testset "Empty file" begin
      @test_throws "Invalid definition file, not enough sections" read_parser_definition_file(from_current_path("resources/parser/definition_reader/empty_file.jpar"))
    end

    @testset "Not enough sections" begin
      @test_throws "Invalid definition file, not enough sections" read_parser_definition_file(from_current_path("resources/parser/definition_reader/not_enough_sections.jpar"))
    end

    @testset "Option outside definitions" begin
      @test_throws "Option %option misplaced outside of definitions section" read_parser_definition_file(from_current_path("resources/parser/definition_reader/option_outside_definitions.jpar"))
    end

    @testset "%Type outside definitions" begin
      @test_throws "Type definition %type <Int> Misplaced outside of definitions sectio" read_parser_definition_file(from_current_path("resources/parser/definition_reader/type_outside_definitions.jpar"))
    end

    @testset "%Token outside definitions" begin
      @test_throws "Token definition %token MISPLACED \"misplaced\" outside of definitions section" read_parser_definition_file(from_current_path("resources/parser/definition_reader/token_outside_definitions.jpar"))
    end

    @testset "%Token redefinition" begin
      @test_throws "Token %token ONE \"redefined\" already defined" read_parser_definition_file(from_current_path("resources/parser/definition_reader/token_redefinition.jpar"))
    end

    @testset "%Start outside productions" begin
      @test_throws "Start definition %start misplaced outside of productions section" read_parser_definition_file(from_current_path("resources/parser/definition_reader/start_outside_productions.jpar"))
    end

    @testset "%Start redefinition" begin
      @test_throws "Start symbol already defined" read_parser_definition_file(from_current_path("resources/parser/definition_reader/start_redefinition.jpar"))
    end

    @testset "No %start symbol" begin
      @test_throws "No start symbol defined" read_parser_definition_file(from_current_path("resources/parser/definition_reader/no_start_symbol.jpar"))
    end

    @testset "Production outside productions" begin
      @test_throws "Production start -> MISPLACED outside of productions section" read_parser_definition_file(from_current_path("resources/parser/definition_reader/production_outside_productions.jpar"))
    end

    @testset "Repeated lhs symbol in productions" begin
      @test_throws "Production left-hand side start repeated" read_parser_definition_file(from_current_path("resources/parser/definition_reader/repeated_lhs.jpar"))
    end

    @testset "Production alternative outside productions" begin
      @test_throws "Production alternative | MISPLACED outside of productions section" read_parser_definition_file(from_current_path("resources/parser/definition_reader/production_alt_outside_productions.jpar"))
    end

    @testset "Mixed letter cases in productions" begin
      @test_throws "Symbol in production has to be either lowercase or uppercase (got MixEd)" read_parser_definition_file(from_current_path("resources/parser/definition_reader/mixed_letter_cases_in_productions.jpar"))
    end

    @testset "Invalid char/s inside definition file" begin
      @test_throws "Invalid characters in definition file, ?, at 52" read_parser_definition_file(from_current_path("resources/parser/definition_reader/invalid_chars.jpar"))
    end
  end

  @testset "Correctly parses definition files" begin
    @testset "Empty sections" begin
    end

    @testset "All sections present" begin
    end
  end
end
