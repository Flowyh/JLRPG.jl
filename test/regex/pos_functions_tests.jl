@testset "Nullable" begin
  @testset "Character/PossibleCharacters are not nullable" begin
    @test nullable(treeify("a", :a).left) == false
    @test nullable(treeify(raw"\$", :dollar).left) == false
    @test nullable(treeify(raw"\n", :newline).left) == false
    @test nullable(treeify("[a-z]", :a_z).left) == false
  end

  @testset "Concatenation does not break nullability" begin
    @test nullable(treeify("ab", :ab)) == false
    @test nullable(treeify(raw"\$\n", :dollar_line)) == false
    @test nullable(treeify("a[a-z]", :a_a_z)) == false
  end

  @testset "KleeneStar is nullable" begin
    @test nullable(treeify("a*", :a_star).left) == true
    @test nullable(treeify(raw"\$*", :dollar_star).left) == true
    @test nullable(treeify("[a-z]*", :a_z_star).left) == true
  end

  @testset "Concatenation with KleeneStar is not nullable" begin
    @test nullable(treeify("a*a", :a_star_a)) == false
    @test nullable(treeify(raw"\$*\$", :dollar_star_dollar)) == false
    @test nullable(treeify("[a-z]*[a-z]", :a_z_star_a_z)) == false
  end

  @testset "Optional is nullable" begin
    @test nullable(treeify("a?", :a_question).left) == true
    @test nullable(treeify(raw"\$?", :dollar_question).left) == true
    @test nullable(treeify("[a-z]?", :a_z_question).left) == true
  end

  @testset "Concatenation with Optional is not nullable" begin
    @test nullable(treeify("a?a", :a_question_a)) == false
    @test nullable(treeify(raw"\$?\$", :dollar_question_dollar)) == false
    @test nullable(treeify("[a-z]?[a-z]", :a_z_question_a_z)) == false
  end

  @testset "AtLeastOne nullability depends on child" begin
    @test nullable(treeify("a+", :a_plus).left) == false
    @test nullable(treeify(raw"\$+", :dollar_plus).left) == false
    @test nullable(treeify("[a-z]+", :a_z_plus).left) == false
    @test nullable(treeify("(a?)+", :a_question_plus).left) == nullable(treeify("(a?)+", :a_question_plus).left.child)
  end

  @testset "Alternation with KleeneStar or Optional is nullable" begin
    @test nullable(treeify("a*|a", :a_star_or_a).left) == true
    @test nullable(treeify("a?|a", :a_question_or_a).left) == true
  end

  @testset "Alternation with not nullable children is not nullable" begin
    @test nullable(treeify("a|[a-z]", :a_or_a_z).left) == false
    @test nullable(treeify("a|a", :a_or_a).left) == false
    @test nullable(treeify("a+|a", :a_plus_or_a).left) == false
  end
end

@testset "Firstpos" begin
  @testset "Firstpos of Character/PossibleCharacters is always itself" begin
    @test firstpos(treeify("a", :a).left) == [1]
    @test firstpos(treeify(raw"\$", :dollar).left) == [1]
    @test firstpos(treeify(raw"\n", :newline).left) == [1]
    @test firstpos(treeify("[a-z]", :a_z).left) == [1]
  end

  @testset "Firstpos of End is always itself" begin
    @test firstpos(treeify("a", :a).right) == [2]
    @test firstpos(treeify(raw"\$", :dollar).right) == [2]
    @test firstpos(treeify(raw"\n", :newline).right) == [2]
    @test firstpos(treeify("[a-z]", :a_z).right) == [2]
  end

  @testset "Firstpos of Concatenation depends on left child's nullability" begin
    @testset "If left child is not nullable, firstpos of concat is firspos of left child" begin
      @test firstpos(treeify("ab", :ab).left) == [1]
      @test firstpos(treeify(raw"\$\n", :dollar_line).left) == [1]
      @test firstpos(treeify("[a-z]", :a_z)) == [1] # Concat with End
    end

    @testset "If left is nullable, firspos of concat is union of left and right children firstpos" begin
      @test firstpos(treeify("a?b", :a_question_b).left) == [1, 2]
      @test firstpos(treeify("[a-z]*b*c", :a_z_star_b_star_c).left) == [1, 2, 3]
      @test firstpos(treeify("([a-z]|b)*c", :a_z_or_b_star_c).left) == [1, 2, 3]
      @test firstpos(treeify("a?b?c?", :a_question_b_question_c)) == [1, 2, 3, 4] # Concat with End
    end
  end

  @testset "Firstpos of Alternation is a union" begin
    @test firstpos(treeify("a|b", :a_or_b).left) == [1, 2]
    @test firstpos(treeify("a|b|c", :a_or_b_or_c).left) == [1, 2, 3]
    @test firstpos(treeify("a|b|c", :a_or_b_or_c).left.left) == [1, 2]
  end

  @testset "Firstpos of KleeneStar/AtLeastOne/Optional depends on child" begin
    @test firstpos(treeify("a*", :a_star).left) == [1]
    @test firstpos(treeify("a+", :a_plus).left) == [1]
    @test firstpos(treeify("a?", :a_question).left) == [1]
    @test firstpos(treeify("([a-z]|b)*", :a_z_or_b_star).left) == [1, 2]
    @test firstpos(treeify("([a-z]|b|c)+", :a_z_or_b_or_c_plus).left) == [1, 2, 3]
    @test firstpos(treeify("(a?|b?)?", :a_question_or_b_question_question).left) == [1, 2]
  end
end

@testset "Lastpos" begin
  @testset "Lastpos of Character/PossibleCharacters is always itself" begin
    @test lastpos(treeify("a", :a).left) == [1]
    @test lastpos(treeify(raw"\$", :dollar).left) == [1]
    @test lastpos(treeify(raw"\n", :newline).left) == [1]
    @test lastpos(treeify("[a-z]", :a_z).left) == [1]
  end

  @testset "Lastpos of End is always itself" begin
    @test lastpos(treeify("a", :a).right) == [2]
    @test lastpos(treeify(raw"\$", :dollar).right) == [2]
    @test lastpos(treeify(raw"\n", :newline).right) == [2]
    @test lastpos(treeify("[a-z]", :a_z).right) == [2]
  end

  @testset "Lastpos of Concatenation depends on right child's nullability" begin
    @testset "If right child is not nullable, lastpos of concat is lastpos of right child" begin
      @test lastpos(treeify("ab", :ab).left) == [2]
      @test lastpos(treeify(raw"\$\n", :dollar_line).left) == [2]
      @test lastpos(treeify("[a-z]b", :a_z_b)) == [3] # Concat with End
    end

    @testset "If right is nullable, lastpos of concat is union of left and right children lastpos" begin
      @test lastpos(treeify("ab?", :a_b_question).left) == [1, 2]
      @test lastpos(treeify("[a-z]b*c*", :a_z_b_star_c_star).left) == [1, 2, 3]
      @test lastpos(treeify("([a-z]|b)c*", :a_z_or_b_c_star).left) == [1, 2, 3]
      @test lastpos(treeify("a?b?c?", :a_question_b_question_c)) == [4] # Concat with End
    end
  end

  @testset "Lastpos of Alternation is a union" begin
    @test lastpos(treeify("a|b", :a_or_b).left) == [1, 2]
    @test lastpos(treeify("a|b|c", :a_or_b_or_c).left) == [1, 2, 3]
    @test lastpos(treeify("a|b|c", :a_or_b_or_c).left.left) == [1, 2]
  end

  @testset "Lastpos of KleeneStar/AtLeastOne/Optional depends on child" begin
    @test lastpos(treeify("a*", :a_star).left) == [1]
    @test lastpos(treeify("a+", :a_plus).left) == [1]
    @test lastpos(treeify("a?", :a_question).left) == [1]
    @test lastpos(treeify("([a-z]|b)*", :a_z_or_b_star).left) == [1, 2]
    @test lastpos(treeify("([a-z]|b|c)+", :a_z_or_b_or_c_plus).left) == [1, 2, 3]
    @test lastpos(treeify("(a?|b?)?", :a_question_or_b_question_question).left) == [1, 2]
  end
end
