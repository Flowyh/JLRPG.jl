@testset "Definition files reader" begin
  @testset "Throws errors for invalid definition files" begin
    @testset "Empty file" begin
      @test_throws "Invalid definition file, not enough sections" read_parser_definition_file(abspaths("resources/parser/definition_reader/erroneous/empty_file.jpar"))
    end

    @testset "Not enough sections" begin
      @test_throws "Invalid definition file, not enough sections" read_parser_definition_file(abspaths("resources/parser/definition_reader/erroneous/not_enough_sections.jpar"))
    end

    @testset "Option outside definitions" begin
      path = abspaths("resources/parser/definition_reader/erroneous/option_outside_definitions.jpar")
      error_msg = raw"Option outside of definitions section" * "\n" *
                  raw"       \"%option misplaced\" at " * "$(unexpanduser(path)):5:1"
      @test_throws error_msg read_parser_definition_file(path)
    end

    @testset "%Type outside definitions" begin
      path = abspaths("resources/parser/definition_reader/erroneous/type_outside_definitions.jpar")
      error_msg = raw"Type definition outside of definitions section" * "\n" *
                  raw"       \"%type <Int> misplaced\" at " * "$(unexpanduser(path)):5:1"
      @test_throws error_msg read_parser_definition_file(path)
    end

    @testset "%Type redefinition" begin
      path = abspaths("resources/parser/definition_reader/erroneous/type_redefinition.jpar")
      error_msg = raw"Type already defined" * "\n" *
                  raw"       \"%type <String> redefined\" at " * "$(unexpanduser(path)):4:1"
      @test_throws error_msg read_parser_definition_file(path)
    end

    @testset "%Type neither uppercase nor lowercase" begin
      path = abspaths("resources/parser/definition_reader/erroneous/type_not_lowercase.jpar")
      error_msg = raw"Typed symbol must be either lowercase (nonterminal)" * "\n" *
                  raw"       \"%type <Int> NotLowercase\" at " * "$(unexpanduser(path)):3:1"
      @test_throws error_msg read_parser_definition_file(path)
    end

    @testset "%Token outside definitions" begin
      path = abspaths("resources/parser/definition_reader/erroneous/token_outside_definitions.jpar")
      error_msg = raw"Token definition outside of definitions section" * "\n" *
                  raw"       \"%token MISPLACED \"misplaced\"\" at " * "$(unexpanduser(path)):5:1"
      @test_throws error_msg read_parser_definition_file(path)
    end

    @testset "%Token redefinition" begin
      path = abspaths("resources/parser/definition_reader/erroneous/token_redefinition.jpar")
      error_msg = raw"Token already defined" * "\n" *
                  raw"       \"%token ONE \"redefined\"\" at " * "$(unexpanduser(path)):4:1"
      @test_throws error_msg read_parser_definition_file(path)
    end

    @testset "%Token not uppercase" begin
      path = abspaths("resources/parser/definition_reader/erroneous/token_not_uppercase.jpar")
      error_msg = raw"Token name must be uppercase" * "\n" *
                  raw"       \"%token NotUppercase\" at " * "$(unexpanduser(path)):3:1"
      @test_throws error_msg read_parser_definition_file(path)
    end

    @testset "%Start outside productions" begin
      path = abspaths("resources/parser/definition_reader/erroneous/start_outside_productions.jpar")
      error_msg = raw"Start definition outside of productions section" * "\n" *
                  raw"       \"%start misplaced\" at " * "$(unexpanduser(path)):3:1"
      @test_throws error_msg read_parser_definition_file(path)
    end

    @testset "%Start redefinition" begin
      path = abspaths("resources/parser/definition_reader/erroneous/start_redefinition.jpar")
      error_msg = raw"Start symbol already defined" * "\n" *
                  raw"       \"%start redefined\" at " * "$(unexpanduser(path)):6:1"
      @test_throws error_msg read_parser_definition_file(path)
    end

    @testset "No %start symbol" begin
      path = abspaths("resources/parser/definition_reader/erroneous/no_start_symbol.jpar")
      error_msg = raw"No start symbol detected"
      @test_throws error_msg read_parser_definition_file(path)
    end

    @testset "%start not lowercase" begin
      path = abspaths("resources/parser/definition_reader/erroneous/start_not_lowercase.jpar")
      error_msg = raw"Start symbol must be lowercase" * "\n" *
                  raw"       \"%start NotLowercase\" at " * "$(unexpanduser(path)):5:1"
      @test_throws error_msg read_parser_definition_file(path)
    end

    @testset "%start not a valid nonterminal" begin
      path = abspaths("resources/parser/definition_reader/erroneous/start_not_a_valid_nonterminal.jpar")
      error_msg = raw"Start symbol not a valid nonterminal"
      @test_throws error_msg read_parser_definition_file(path)
    end

    @testset "Production outside productions" begin
      path = abspaths("resources/parser/definition_reader/erroneous/production_outside_productions.jpar")
      error_msg = raw"Production outside of productions section" * "\n" *
                  raw"       \"start -> MISPLACED\" at " * "$(unexpanduser(path)):4:1"
      @test_throws error_msg read_parser_definition_file(path)
    end

    @testset "Empty production with other symbols" begin
      path = abspaths("resources/parser/definition_reader/erroneous/empty_production_with_other_symbols.jpar")
      error_msg = raw"%empty productions cannot be mixed with other symbols" * "\n" *
                  raw"       \"start -> %empty END\" at " * "$(unexpanduser(path)):6:1"
      @test_throws error_msg read_parser_definition_file(path)
    end

    @testset "Repeated lhs symbol in productions" begin
      path = abspaths("resources/parser/definition_reader/erroneous/repeated_lhs.jpar")
      error_msg = raw"Production left-hand side repeated" * "\n" *
                  raw"       \"start -> REPEATED\" at " * "$(unexpanduser(path)):8:1"
      @test_throws error_msg read_parser_definition_file(path)
    end

    @testset "Production lhs not lowercase" begin
      path = abspaths("resources/parser/definition_reader/erroneous/production_lhs_not_lowercase.jpar")
      error_msg = raw"Production left-hand side must be lowercase" * "\n" *
                  raw"       \"Start -> END\" at " * "$(unexpanduser(path)):6:1"
      @test_throws error_msg read_parser_definition_file(path)
    end

    @testset "Production alternative outside productions" begin
      path = abspaths("resources/parser/definition_reader/erroneous/production_alt_outside_productions.jpar")
      error_msg = raw"Production outside of productions section" * "\n" *
                  raw"       \"| MISPLACED\" at " * "$(unexpanduser(path)):4:1"
      @test_throws error_msg read_parser_definition_file(path)
    end

    @testset "Mixed letter cases in productions" begin
      path = abspaths("resources/parser/definition_reader/erroneous/mixed_letter_cases_in_productions.jpar")
      error_msg = raw"Symbol in production has to be either lowercase or uppercase (got MixEd)" * "\n" *
                  raw"       \"start -> MixEd END CaSe\" at " * "$(unexpanduser(path)):6:1"
      @test_throws error_msg read_parser_definition_file(path)
    end

    @testset "Invalid character/s in definition file" begin
      path = abspaths("resources/parser/definition_reader/erroneous/invalid_chars.jpar")
      error_msg = raw"Invalid character/s in definition file" * "\n" *
                  raw"       \"?\" at " * "$(unexpanduser(path)):6:1"
      @test_throws error_msg read_parser_definition_file(path)
    end
  end

  @testset "Correctly parses definition files" begin
    @testset "All sections present" begin
      parser = read_parser_definition_file(abspaths("resources/parser/definition_reader/all_sections.jpar"))

      @test parser == Parser(;
        terminals = [
          :PLUS, :MINUS, :TIMES, :DIVIDE,
          :LPAREN, :RPAREN, :END, :NUMBER
        ],
        nonterminals = [:start, :expr],
        starting = :start,
        productions = Dict(
          :start => [
            ParserProduction(:start, [:expr, :END], raw"println($1)", :Int),
            ParserProduction(:start, EMPTY_PRODUCTION, "println(\"Empty input\")", :Int)
          ],
          :expr => [
            ParserProduction(:expr, [:expr, :PLUS, :expr], raw"$$ = $1 + $3", :Int),
            ParserProduction(:expr, [:expr, :MINUS, :expr], raw"$$ = $1 - $3", :Int),
            ParserProduction(:expr, [:expr, :TIMES, :expr], raw"$$ = $1 * $3", :Int),
            ParserProduction(:expr, [:expr, :DIVIDE, :expr], raw"$$ = $1 / $3", :Int),
            ParserProduction(:expr, [:LPAREN, :expr, :RPAREN], raw"$$ = $2", :Int),
            ParserProduction(:expr, [:NUMBER], raw"$$ = $1.value", :Int)
          ]
        ),
        symbol_types = Dict(
          :expr => :Int,
          :start => :Int,
          :vec => Symbol(raw"Vector{Int}")
        ),
        lexer_tokens = Set(
          :PLUS, Symbol("+"),
          :MINUS, Symbol("-"),
          :TIMES, Symbol("*"),
          :DIVIDE, Symbol("/"),
          :LPAREN, Symbol("("),
          :RPAREN, Symbol(")"),
          :END, :NUMBER
        ),
        lexer_token_aliases = Dict(
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
        code_blocks = [
          "println(\"Code in definitions :o\")",
          "function factorial(n::Int)::Int\n  return n * factorial(n - 1)\nend\n\nfunction __PAR__at_end() # Overloaded JLPG function\n  println(\"Code at the end :o\")\n  return 0\nend"
        ],
        options = ParserOptions()
      )
    end

    @testset "Dragonbook top-down parser grammar (4.28, p. 217)" begin
      parser = read_parser_definition_file(abspaths("resources/parser/definition_reader/dragonbook_4_28_ll.jpar"))

      @test parser == Parser(;
        terminals = [:PLUS, :TIMES, :LPAREN, :RPAREN, :ID],
        nonterminals = [:e, :t, :e_prim, :f, :t_prim],
        starting = :e,
        productions = Dict(
          :e => [
            ParserProduction(:e, [:t, :e_prim])
          ],
          :e_prim => [
            ParserProduction(:e_prim, [:PLUS, :t, :e_prim]),
            ParserProduction(:e_prim, EMPTY_PRODUCTION)
          ],
          :t => [
            ParserProduction(:t, [:f, :t_prim])
          ],
          :t_prim => [
            ParserProduction(:t_prim, [:TIMES, :f, :t_prim]),
            ParserProduction(:t_prim, EMPTY_PRODUCTION)
          ],
          :f => [
            ParserProduction(:f, [:LPAREN, :e, :RPAREN]),
            ParserProduction(:f, [:ID])
          ]
        ),
        symbol_types = Dict(
          :e => :Nothing,
          :e_prim => :Nothing,
          :t => :Nothing,
          :t_prim => :Nothing,
          :f => :Nothing
        ),
        lexer_tokens = Set(
          :PLUS, Symbol("+"),
          :TIMES, Symbol("*"),
          :LPAREN, Symbol("("),
          :RPAREN, Symbol(")"),
          :ID
        ),
        lexer_token_aliases = Dict(
          :PLUS => Symbol("+"),
          Symbol("+") => :PLUS,
          :TIMES => Symbol("*"),
          Symbol("*") => :TIMES,
          :LPAREN => Symbol("("),
          Symbol("(") => :LPAREN,
          :RPAREN => Symbol(")"),
          Symbol(")") => :RPAREN
        ),
        code_blocks = Vector{String}(),
        options = ParserOptions()
      )
    end
  end
end
