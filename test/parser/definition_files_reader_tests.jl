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
      @test_throws "No start symbol detected" read_parser_definition_file(from_current_path("resources/parser/definition_reader/no_start_symbol.jpar"))
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
    @testset "All sections present" begin
      parser = read_parser_definition_file(from_current_path("resources/parser/definition_reader/all_sections.jpar"))

      @test parser == Parser(
        Set(
          :PLUS, :MINUS, :TIMES, :DIVIDE,
          :LPAREN, :RPAREN, :END, :NUMBER
        ),
        Set(:expr, :start),
        :start,
        Dict(
          :start => [
            ParserProduction(:start, [:expr, :END], raw" println($1) ", :Int)
          ],
          :expr => [
            ParserProduction(:expr, [:expr, :PLUS, :expr], raw" $$ = $1 + $3 ", :Int),
            ParserProduction(:expr, [:expr, :MINUS, :expr], raw" $$ = $1 - $3 ", :Int),
            ParserProduction(:expr, [:expr, :TIMES, :expr], raw" $$ = $1 * $3 ", :Int),
            ParserProduction(:expr, [:expr, :DIVIDE, :expr], raw" $$ = $1 / $3 ", :Int),
            ParserProduction(:expr, [:LPAREN, :expr, :RPAREN], raw" $$ = $2 ", :Int),
            ParserProduction(:expr, [:NUMBER], raw" $$ = $1 ", :Int)
          ]
        ),
        Dict(
          :expr => :Int,
          :NUMBER => :Int,
          :start => :Int
        ),
        Set(
          :PLUS, Symbol("+"),
          :MINUS, Symbol("-"),
          :TIMES, Symbol("*"),
          :DIVIDE, Symbol("/"),
          :LPAREN, Symbol("("),
          :RPAREN, Symbol(")"),
          :END, :NUMBER
        ),
        Dict(
          :PLUS => Symbol("+"),
          Symbol("+") => :PLUS,
          :MINUS => Symbol("-"),
          Symbol("-") => :MINUS,
          :TIMES => Symbol("*"),
          Symbol("*") => :TIMES,
          :DIVIDE => Symbol("/"),
          Symbol("/") => :DIVIDE,
          :LPAREN => Symbol("("),
          Symbol("(") => :LPAREN,
          :RPAREN => Symbol(")"),
          Symbol(")") => :RPAREN
        ),
        [
          "println(\"Code in definitions :o\")",
          "function factorial(n::Int)::Int\n  return n * factorial(n - 1)\nend\n\nfunction at_end() # Overloaded JLPG function\n  println(\"Code at the end :o\")\n  return 0\nend"
        ],
        ParserOptions()
      )
    end
  end
end