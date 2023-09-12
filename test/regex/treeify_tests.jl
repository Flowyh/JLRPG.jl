# TODO: Add precedence tests

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

    # Invalid operators/tokens are not possible, since _treeify method is hidden from the user. You cannot call it will malformed tokens.
  end

  @testset "End node concatenation" begin
    @test treeify("a", :a) == Concatenation(
      Character('a'), 
      End("a", :a, doNothing)
    )
  end

  @testset "Characters" begin
    @test treeify("a", :a) == Concatenation(
      Character('a'), 
      End("a", :a, doNothing)
    )
    @test treeify(raw"\$", :dollar) == Concatenation(
      Character('\$'), 
      End(raw"\$", :dollar, doNothing)
    )
    @test treeify(".", :any; charset=:ASCII) == Concatenation(
      CharsetToAllPossibleCharacters[:ASCII], 
      End(".", :any, doNothing)
    )
  end

  @testset "Basic concatenation" begin
    @test treeify("ab", :ab) == Concatenation(
      Concatenation(
        Character('a'),
        Character('b')
      ),
      End("ab", :ab, doNothing)
    )

    @test treeify("abc", :abc) == Concatenation(
      Concatenation(
        Concatenation(
          Character('a'),
          Character('b')
        ),
        Character('c')
      ),
      End("abc", :abc, doNothing)
    )
  end

  @testset "Operators" begin
    @test treeify("a*", :zero_or_more_a) == Concatenation(
      KleeneStar(Character('a')),
      End("a*", :zero_or_more_a, doNothing)
    )

    @test treeify("a+", :one_or_more_a) == Concatenation(
      AtLeastOne(Character('a')),
      End("a+", :one_or_more_a, doNothing)
    )

    @test treeify("a?", :zero_or_one_a) == Concatenation(
      Optional(Character('a')),
      End("a?", :zero_or_one_a, doNothing)
    )

    @test treeify("a|b", :a_or_b) == Concatenation(
      Alternation(
        Character('a'),
        Character('b')
      ),
      End("a|b", :a_or_b, doNothing)
    )
  end

  @testset "Parantheses" begin
    @testset "Unnecessary parantheses" begin
      @test treeify("(a)", :a) == Concatenation(
        Character('a'), 
        End("(a)", :a, :DoNothing)
      )

      @test treeify("(a)(b)(c)", :abc) == Concatenation(
        Concatenation(
          Concatenation(
            Character('a'),
            Character('b')
          ),
          Character('c')
        ),
        End("(a)(b)(c)", :abc, :DoNothing)
      )

      @test treeify("(((a))((b))(c))", :abc) == Concatenation(
        Concatenation(
          Concatenation(
            Character('a'),
            Character('b')
          ),
          Character('c')
        ),
        End("(((a))((b))(c))", :abc, :DoNothing)
      )
    end

    @testset "Grouping of regexes" begin
      @test treeify("(ab)*", :ab_star) == Concatenation(
        KleeneStar(
          Concatenation(
            Character('a'),
            Character('b')
          )
        ),
        End("(ab)*", :ab_star, :DoNothing)
      )
      @test treeify("(ab)+(cd)*", :ab_plus_cd_star) == Concatenation(
        Concatenation(
          AtLeastOne(
            Concatenation(
              Character('a'),
              Character('b')
            )
          ),
          KleeneStar(
            Concatenation(
              Character('c'),
              Character('d')
            )
          )
        ),
        End("(ab)+(cd)*", :ab_plus_cd_star, :DoNothing)
      )
    end

    @testset "Nesting" begin 
      @test treeify("((a*b)*c)+", :nested) == Concatenation(
        AtLeastOne(
          Concatenation(
            KleeneStar(
              Concatenation(
                KleeneStar(
                  Character('a'),
                ),
                Character('b')
              )
            ),
            Character('c')
          )
        ),
        End("((a*b)*c)+", :nested, :DoNothing)
      )

      @test repr(treeify("(a*([a-z]+c)|bc)*", :nested)) == repr(Concatenation(
        KleeneStar(
          Alternation(
            Concatenation(
              KleeneStar(
                Character('a')
              ),
              Concatenation(
                AtLeastOne(
                  PossibleCharacters([
                    'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 
                    'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 
                    'u', 'v', 'w', 'x', 'y', 'z'
                  ])
                ),
                Character('c')
              )
            ),
            Concatenation(
              Character('b'),
              Character('c')
            )
          )
        ),
        End("(a*([a-z]+c)|bc)*", :nested, :DoNothing)
      ))
    end
  end

  @testset "Character classes" begin
    @test repr(treeify("[a]", :a)) == repr(Concatenation(
      PossibleCharacters(['a']), 
      End("[a]", :a, :DoNothing)
    ))

    @test repr(treeify("[a-z]", :a_to_z)) == repr(Concatenation(
      PossibleCharacters([
        'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 
        'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 
        'u', 'v', 'w', 'x', 'y', 'z'
      ]), 
      End("[a-z]", :a_to_z, :DoNothing)
    ))

    @test repr(treeify("[0-9]", :zero_to_nine)) == repr(Concatenation(
      PossibleCharacters(['0', '1', '2', '3', '4', '5', '6', '7', '8', '9']), 
      End("[0-9]", :zero_to_nine, :DoNothing)
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
      ]), 
      End("[a-zA-Z0-9]", :alphanumeric, :DoNothing)
    ))

    @test repr(treeify(raw"[$|^+-. \n\t\r]", :special_chars)) == repr(Concatenation(
      PossibleCharacters(['\t', '\n', '\r', ' ', '\$', '+', ',', '-', '.', '^', '|']), 
      End(raw"[$|^+-. \n\t\r]", :special_chars, :DoNothing)
    ))
  end

  @testset "Complex regexes" begin
    @testset "Random number (at least one digit)" begin
      @test repr(treeify("[0-9]+", :one_number)) == repr(Concatenation(
        AtLeastOne(
          PossibleCharacters(['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'])
        ),
        End("[0-9]+", :one_number, :DoNothing)
      ))
    end

    @testset "Two random numbers separated by dash ('-')" begin
      @test repr(treeify("[0-9]+-[0-9]+", :two_numbers)) == repr(Concatenation(
        Concatenation(
          Concatenation(
            AtLeastOne(
              PossibleCharacters(['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'])
            ),
            Character('-')
          ),
          AtLeastOne(
            PossibleCharacters(['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'])
          )
        ),
        End("[0-9]+-[0-9]+", :two_numbers, :DoNothing)
      ))
    end

    @testset "Floating point numbers" begin
      @test repr(treeify(raw"[0-9]+\.[0-9]+", :floating_point)) == repr(Concatenation(
        Concatenation(
          Concatenation(
            AtLeastOne(
              PossibleCharacters(['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'])
            ),
            Character('.')
          ),
          AtLeastOne(
            PossibleCharacters(['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'])
          )
        ),
        End(raw"[0-9]+\.[0-9]+", :floating_point, :DoNothing)
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
          ]), 
          KleeneStar(
            PossibleCharacters([
              '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 
              'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 
              'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 
              'U', 'V', 'W', 'X', 'Y', 'Z', '_', 'a', 'b', 'c', 
              'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 
              'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 
              'x', 'y', 'z'
            ])
          )
        ),
        End("[a-zA-Z_][_a-zA-Z0-9]*", :identifier, :DoNothing)
      ))
    end

    @testset "Proper number" begin
      @test repr(treeify("[1-9]+[0-9]*", :number)) == repr(Concatenation(
        Concatenation(
          AtLeastOne(
            PossibleCharacters(['1', '2', '3', '4', '5', '6', '7', '8', '9'])
          ),
          KleeneStar(
            PossibleCharacters(['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'])
          )
        ),
        End("[1-9]+[0-9]*", :number, :DoNothing)
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
              ]), 
              KleeneStar(
                PossibleCharacters([
                  '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 
                  'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 
                  'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 
                  'U', 'V', 'W', 'X', 'Y', 'Z', '_', 'a', 'b', 'c', 
                  'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 
                  'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 
                  'x', 'y', 'z'
                ])
              )
            ), 
            Character('(')
          ), 
          Character(')')
        ), 
        End(raw"[a-zA-Z_][a-zA-Z0-9_]*\(\)", :function_call, :DoNothing)
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
                              PossibleCharacters(['0', '1', '2', '3', '4', '5', '6', '7', '8', '9']),
                              PossibleCharacters(['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'])
                            ),
                            PossibleCharacters(['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'])
                          ),
                          Character('-')
                        ),
                        PossibleCharacters(['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'])
                      ),
                      PossibleCharacters(['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'])
                    ),
                    PossibleCharacters(['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'])
                  ),
                  Character('-')
                ),
                PossibleCharacters(['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'])
              ),
              PossibleCharacters(['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'])
            ),
            PossibleCharacters(['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'])
          ),
          End("[0-9][0-9][0-9]-[0-9][0-9][0-9]-[0-9][0-9][0-9]", :phone_number, :DoNothing)
        )
      )
    end
  end
end