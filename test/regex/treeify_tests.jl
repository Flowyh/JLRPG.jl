@testset "Treeify" begin
  @testset "Empty regex" begin
    @test_throws "Empty regex" treeify("", :Nothing)
  end
  @testset "End node concatenation" begin
    @test treeify("a", :a) == Concatenation(
      Character('a'), 
      End("a", :a, doNothing)
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

  @testset "Character classes" begin
    @test repr(treeify("[a]", :a)) == "Concatenation[\
      CharacterClass(['a']), End([a], :a, :DoNothing)\
    ]"
    @test repr(treeify("[a-z]", :a_to_z)) == "Concatenation[\
      CharacterClass(['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', \
      'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', \
      't', 'u', 'v', 'w', 'x', 'y', 'z']), \
      End([a-z], :a_to_z, :DoNothing)\
    ]"
    @test repr(treeify("[0-9]", :zero_to_nine)) == "Concatenation[\
      CharacterClass(['0', '1', '2', '3', '4', '5', '6', '7', '8', '9']), \
      End([0-9], :zero_to_nine, :DoNothing)\
    ]"
    @test repr(treeify(raw"[$|^+-. \n\t\r]", :special_chars)) == "Concatenation[\
      CharacterClass(['\\t', '\\n', '\\r', ' ', '\$', '+', ',', '-', '.', '^', '|']), \
      End([\$|^+-. \\n\\t\\r], :special_chars, :DoNothing)\
    ]"
  end

  @testset "Complex regexes" begin
    @testset "Phone number (at least one digit)" begin
      @test repr(treeify("[0-9]+", :one_digit)) ==  "Concatenation[\
        AtLeastOne[\
          CharacterClass(['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'])\
        ], \
        End([0-9]+, :one_digit, :DoNothing)\
      ]"
    end

    @testset "Floating point numbers" begin
      @test repr(treeify(raw"[0-9]+\.[0-9]+", :floating_point)) == "Concatenation[\
        Concatenation[\
          Concatenation[\
            AtLeastOne[\
              CharacterClass(['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'])\
            ], \
            Character(\\.)\
          ], \
          AtLeastOne[\
            CharacterClass(['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'])\
          ], \
        ], \
        End([0-9]+.[0-9]+, :floating_point, :DoNothing)\
      ]"
    end

    @testset "Identifier" begin
      @test repr(treeify("[a-zA-Z_][_a-zA-Z0-9]*", :identifier)) == "Concatenation[\
        Concatenation[\
          CharacterClass(['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', \
          'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', \
          't', 'u', 'v', 'w', 'x', 'y', 'z', 'A', 'B', 'C', 'D', \
          'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', \
          'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', \
          '_']), \
          KleeneStar[\
            CharacterClass(['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', \
            'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', \
            't', 'u', 'v', 'w', 'x', 'y', 'z', 'A', 'B', 'C', 'D', \
            'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', \
            'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', \
            '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '_'])\
          ]\
        ], \
        End([a-zA-Z_][a-ZA-Z_0-9]*, :identifier, :DoNothing)\
      ]"
    end

    @testset "Number" begin
      @test repr(treeify("[1-9]+[0-9]*", :number)) == "Concatenation[\
        Concatenation[\
          AtLeastOne[\
            CharacterClass(['1', '2', '3', '4', '5', '6', '7', '8', '9'])\
          ], \
          KleeneStar[\
            CharacterClass(['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'])\
          ]\
        ], \
        End([1-9]+[0-9]*, :number, :DoNothing)\
      ]"
    end

    @testset "Function call (no params)" begin
      @test repr(treeify(raw"[a-zA-Z_][a-zA-Z0-9_]*\(\)", :function_call)) == "Concatenation[\
        Concatenation[\
          Concatenation[\
            Concatenation[\
              CharacterClass(['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', \
              'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', \
              'T', 'U', 'V', 'W', 'X', 'Y', 'Z', '_', 'a', 'b', 'c', \
              'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', \
              'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z']), \
              KleeneStar[\
                CharacterClass(['0', '1', '2', '3', '4', '5', '6', '7', \
                '8', '9', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', \
                'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', \
                'U', 'V', 'W', 'X', 'Y', 'Z', '_', 'a', 'b', 'c', 'd', \
                'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', \
                'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z']\
            ], \
            Character(()\
          ], \
        Character())\
        End([a-zA-Z_][a-ZA-Z_0-9]*\\(\\), :function_call, :DoNothing)\
      ]"
    end

    @testset "Phone number (9-digit)" begin
      @test repr(treeify(
        "[0-9][0-9][0-9]-[0-9][0-9][0-9]-[0-9][0-9][0-9]", 
        :phone_number
      )) == "Concatenation[\
              Concatenation[\
                Concatenation[\
                  Concatenation[\
                    Concatenation[\
                      Concatenation[\
                        Concatenation[\
                          Concatenation[\
                            Concatenation[\
                              Concatenation[\
                                Concatenation[\
                                  CharacterClass(['0', '1', '2', '3', '4', '5', '6', '7', '8', '9']), \
                                  CharacterClass(['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'])\
                                ], \
                                CharacterClass(['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'])\
                              ], \
                              Character(-)\
                            ], \
                            CharacterClass(['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'])\
                          ], \
                          CharacterClass(['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'])\
                        ], \
                        CharacterClass(['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'])\
                      ], \
                      Character(-)\
                    ], \
                    CharacterClass(['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'])\
                  ], \
                  CharacterClass(['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'])\
                ], \
                CharacterClass(['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'])\
              ], \
              End([0-9][0-9][0-9]-[0-9][0-9][0-9]-[0-9][0-9][0-9], :phone_number, :DoNothing)\
            ]"
    end
  end
end