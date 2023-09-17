# TODO: Add precedence tests
# TODO: Add line_start and line_end tests 
#       (caret and dollar can only appear at the beginning or end of regex)

@testset "Treeify" begin
  @testset "Errors" begin
    @testset "Empty regex" begin
      @test_throws "Empty regex" treeify("", :Nothing)
    end

    @testset "Mismatched parantheses" begin
      @test_throws "Mismatched parentheses" treeify(")", :Nothing)
      @test_throws "Mismatched parentheses" treeify("(", :Nothing)
      @test_throws "Mismatched parentheses" treeify("(()", :Nothing)
      @test_throws "Mismatched parentheses" treeify("())", :Nothing)
      @test_throws "Mismatched parentheses" treeify(")(", :Nothing)
      @test_throws "Mismatched parentheses" treeify("((((((((((())", :Nothing)
      @test_throws "Mismatched parentheses" treeify(")))))))))))((", :Nothing)
    end

    @testset "Invalid regexes" begin
      @test_throws "Not enough operands for operator: $star" treeify("*", :Nothing) == :Nothing
      @test_throws "Not enough operands for operator: $plus" treeify("+", :Nothing) == :Nothing
      @test_throws "Not enough operands for operator: $optional" treeify("?", :Nothing) == :Nothing
      @test_throws "Not enough operands for operator: $alternation" treeify("|", :Nothing) == :Nothing
    end
    # Invalid operators/tokens are not possible, since _treeify method is hidden from the user. You cannot call it will malformed tokens.
  end

  @testset "End node concatenation" begin
    @test repr(treeify("a", :a)) == repr(Concatenation(
      Character('a', 1), 
      End("a", :a, 2)
    ))
  end

  @testset "Characters" begin
    @test repr(treeify("a", :a)) == repr(Concatenation(
      Character('a', 1), 
      End("a", :a, 2)
    ))
    @test repr(treeify(raw"\$", :dollar)) == repr(Concatenation(
      Character('\$', 1), 
      End(raw"\$", :dollar, 2)
    ))
    @test repr(treeify(".", :any; charset=:ASCII)) == repr(Concatenation(
      PossibleCharacters(
        CharsetToAllCharacters[:ASCII], 
        1
      ),
      End(".", :any, 2)
    ))
  end

  @testset "Basic concatenation" begin
    @test repr(treeify("ab", :ab)) == repr(Concatenation(
      Concatenation(
        Character('a', 1),
        Character('b', 2)
      ),
      End("ab", :ab, 3)
    ))

    @test repr(treeify("abc", :abc)) == repr(Concatenation(
      Concatenation(
        Concatenation(
          Character('a', 1),
          Character('b', 2)
        ),
        Character('c', 3)
      ),
      End("abc", :abc, 4)
    ))
  end

  @testset "Operators" begin
    @test repr(treeify("a*", :zero_or_more_a)) == repr(Concatenation(
      KleeneStar(Character('a', 1)),
      End("a*", :zero_or_more_a, 2)
    ))

    @test repr(treeify("a+", :one_or_more_a)) == repr(Concatenation(
      AtLeastOne(Character('a', 1)),
      End("a+", :one_or_more_a, 2)
    ))

    @test repr(treeify("a?", :zero_or_one_a)) == repr(Concatenation(
      Optional(Character('a', 1)),
      End("a?", :zero_or_one_a, 2)
    ))

    @test repr(treeify("a|b", :a_or_b)) == repr(Concatenation(
      Alternation(
        Character('a', 1),
        Character('b', 2)
      ),
      End("a|b", :a_or_b, 3)
    ))
  end

  @testset "Parantheses" begin
    @testset "Unnecessary parantheses" begin
      @test repr(treeify("(a)", :a)) == repr(Concatenation(
        Character('a', 1), 
        End("(a)", :a, 2)
      ))

      @test repr(treeify("(a)(b)(c)", :abc)) == repr(Concatenation(
        Concatenation(
          Concatenation(
            Character('a', 1),
            Character('b', 2)
          ),
          Character('c', 3)
        ),
        End("(a)(b)(c)", :abc, 4)
      ))

      @test repr(treeify("(((a))((b))(c))", :abc)) == repr(Concatenation(
        Concatenation(
          Concatenation(
            Character('a', 1),
            Character('b', 2)
          ),
          Character('c', 3)
        ),
        End("(((a))((b))(c))", :abc, 4)
      ))
    end

    @testset "Grouping of regexes" begin
      @test repr(treeify("(ab)*", :ab_star)) == repr(Concatenation(
        KleeneStar(
          Concatenation(
            Character('a', 1),
            Character('b', 2)
          )
        ),
        End("(ab)*", :ab_star, 3)
      ))

      @test repr(treeify("(ab)+(cd)*", :ab_plus_cd_star)) == repr(Concatenation(
        Concatenation(
          AtLeastOne(
            Concatenation(
              Character('a', 1),
              Character('b', 2)
            )
          ),
          KleeneStar(
            Concatenation(
              Character('c', 3),
              Character('d', 4)
            )
          )
        ),
        End("(ab)+(cd)*", :ab_plus_cd_star, 5)
      ))
    end

    @testset "Nesting" begin 
      @test repr(treeify("((a*b)*c)+", :nested)) == repr(Concatenation(
        AtLeastOne(
          Concatenation(
            KleeneStar(
              Concatenation(
                KleeneStar(
                  Character('a', 1),
                ),
                Character('b', 2)
              )
            ),
            Character('c', 3)
          )
        ),
        End("((a*b)*c)+", :nested, 4)
      ))

      @test repr(treeify("(a*([a-z]+c)|bc)*", :nested)) == repr(Concatenation(
        KleeneStar(
          Alternation(
            Concatenation(
              KleeneStar(
                Character('a', 1)
              ),
              Concatenation(
                AtLeastOne(
                  PossibleCharacters([
                    'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 
                    'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 
                    'u', 'v', 'w', 'x', 'y', 'z'
                  ], 2)
                ),
                Character('c', 3)
              )
            ),
            Concatenation(
              Character('b', 4),
              Character('c', 5)
            )
          )
        ),
        End("(a*([a-z]+c)|bc)*", :nested, 6)
      ))
    end
  end

  @testset "Character classes" begin
    @test repr(treeify("[a]", :a)) == repr(Concatenation(
      PossibleCharacters(['a'], 1), 
      End("[a]", :a, 2)
    ))

    @test repr(treeify("[a-z]", :a_to_z)) == repr(Concatenation(
      PossibleCharacters([
        'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 
        'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 
        'u', 'v', 'w', 'x', 'y', 'z'
      ], 1), 
      End("[a-z]", :a_to_z, 2)
    ))

    @test repr(treeify("[0-9]", :zero_to_nine)) == repr(Concatenation(
      PossibleCharacters(['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'], 1), 
      End("[0-9]", :zero_to_nine, 2)
    ))

    @test repr(treeify("[a-zA-Z0-9]", :alphanumeric)) == repr(Concatenation(
      PossibleCharacters([
        '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 
        'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 
        'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 
        'U', 'V', 'W', 'X', 'Y', 'Z', 'a', 'b', 'c', 'd', 
        'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 
        'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 
        'y', 'z'
      ], 1), 
      End("[a-zA-Z0-9]", :alphanumeric, 2)
    ))

    @test repr(treeify(raw"[$|^+-. \n\t\r]", :special_chars)) == repr(Concatenation(
      PossibleCharacters(['\t', '\n', '\r', ' ', '\$', '+', ',', '-', '.', '^', '|'], 1), 
      End(raw"[$|^+-. \n\t\r]", :special_chars, 2)
    ))
  end

  @testset "Complex regexes" begin
    @testset "Random number (at least one digit)" begin
      @test repr(treeify("[0-9]+", :one_number)) == repr(Concatenation(
        AtLeastOne(
          PossibleCharacters(['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'], 1)
        ),
        End("[0-9]+", :one_number, 2)
      ))
    end

    @testset "Two random numbers separated by dash ('-')" begin
      @test repr(treeify("[0-9]+-[0-9]+", :two_numbers)) == repr(Concatenation(
        Concatenation(
          Concatenation(
            AtLeastOne(
              PossibleCharacters(['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'], 1)
            ),
            Character('-', 2)
          ),
          AtLeastOne(
            PossibleCharacters(['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'], 3)
          )
        ),
        End("[0-9]+-[0-9]+", :two_numbers, 4)
      ))
    end

    @testset "Floating point numbers" begin
      @test repr(treeify(raw"[0-9]+\.[0-9]+", :floating_point)) == repr(Concatenation(
        Concatenation(
          Concatenation(
            AtLeastOne(
              PossibleCharacters(['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'], 1)
            ),
            Character('.', 2)
          ),
          AtLeastOne(
            PossibleCharacters(['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'], 3)
          )
        ),
        End(raw"[0-9]+\.[0-9]+", :floating_point, 4)
      ))
    end

    @testset "Identifier" begin
      @test repr(treeify("[a-zA-Z_][_a-zA-Z0-9]*", :identifier)) == repr(Concatenation(
        Concatenation(
          PossibleCharacters([
            'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 
            'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T',
            'U', 'V', 'W', 'X', 'Y', 'Z', '_', 'a', 'b', 'c', 
            'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 
            'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 
            'x', 'y', 'z'
          ], 1), 
          KleeneStar(
            PossibleCharacters([
              '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 
              'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 
              'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 
              'U', 'V', 'W', 'X', 'Y', 'Z', '_', 'a', 'b', 'c', 
              'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 
              'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 
              'x', 'y', 'z'
            ], 2)
          )
        ),
        End("[a-zA-Z_][_a-zA-Z0-9]*", :identifier, 3)
      ))
    end

    @testset "Proper number" begin
      @test repr(treeify("[1-9]+[0-9]*", :number)) == repr(Concatenation(
        Concatenation(
          AtLeastOne(
            PossibleCharacters(['1', '2', '3', '4', '5', '6', '7', '8', '9'], 1)
          ),
          KleeneStar(
            PossibleCharacters(['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'], 2)
          )
        ),
        End("[1-9]+[0-9]*", :number, 3)
      ))
    end

    @testset "Function call (no params)" begin
      @test repr(treeify(raw"[a-zA-Z_][a-zA-Z0-9_]*\(\)", :function_call)) == repr(Concatenation(
        Concatenation(
          Concatenation(
            Concatenation(
              PossibleCharacters([
                'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 
                'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 
                'U', 'V', 'W', 'X', 'Y', 'Z', '_', 'a', 'b', 'c', 
                'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 
                'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 
                'x', 'y', 'z'
              ], 1), 
              KleeneStar(
                PossibleCharacters([
                  '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 
                  'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 
                  'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 
                  'U', 'V', 'W', 'X', 'Y', 'Z', '_', 'a', 'b', 'c', 
                  'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 
                  'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 
                  'x', 'y', 'z'
                ], 2)
              )
            ), 
            Character('(', 3)
          ), 
          Character(')', 4)
        ), 
        End(raw"[a-zA-Z_][a-zA-Z0-9_]*\(\)", :function_call, 5)
      ))
    end

    @testset "Phone number (9-digit)" begin
      @test repr(treeify("[0-9][0-9][0-9]-[0-9][0-9][0-9]-[0-9][0-9][0-9]", 
        :phone_number
      )) == repr(
        Concatenation(
          Concatenation(
            Concatenation(
              Concatenation(
                Concatenation(
                  Concatenation(
                    Concatenation(
                      Concatenation(
                        Concatenation(
                          Concatenation(
                            Concatenation(
                              PossibleCharacters(['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'], 1),
                              PossibleCharacters(['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'], 2)
                            ),
                            PossibleCharacters(['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'], 3)
                          ),
                          Character('-', 4)
                        ),
                        PossibleCharacters(['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'], 5)
                      ),
                      PossibleCharacters(['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'], 6)
                    ),
                    PossibleCharacters(['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'], 7)
                  ),
                  Character('-', 8)
                ),
                PossibleCharacters(['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'], 9)
              ),
              PossibleCharacters(['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'], 10)
            ),
            PossibleCharacters(['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'], 11)
          ),
          End("[0-9][0-9][0-9]-[0-9][0-9][0-9]-[0-9][0-9][0-9]", :phone_number, 12)
        )
      )
    end
  end
end