@testset "Tokenize" begin
  @testset "Empty string" begin
    @test tokenize("") == []
  end

  @testset "Characters" begin
    @test tokenize("a")   == [(character, "a")]
    @test tokenize("ab")  == [(character, "a"), (concat, ""), (character, "b")]
    @test tokenize("abc") == [
      (character, "a"),
      (concat, ""),
      (character, "b"),
      (concat, ""), 
      (character, "c")
    ]
    @test tokenize("a b c") == [
      (character, "a"),
      (concat, ""), 
      (character, " "),
      (concat, ""),
      (character, "b"),
      (concat, ""), 
      (character, " "),
      (concat, ""), 
      (character, "c")
    ]
  end

  @testset "Escaped characters" begin
    @test tokenize(raw"\*") == [(escaped_character, raw"\*")]
    @test tokenize(raw"\+") == [(escaped_character, raw"\+")]
    @test tokenize(raw"\$") == [(escaped_character, raw"\$")]
    @test tokenize(raw"\a \b \c") == [
      (escaped_character, raw"\a"),
      (concat, ""), 
      (character, " "),
      (concat, ""),
      (escaped_character, raw"\b"), 
      (concat, ""),
      (character, " "),
      (concat, ""),
      (escaped_character, raw"\c")
    ]
  end

  @testset "Operators" begin
    @test tokenize("*")  == [(operator, "*")]
    @test tokenize("+")  == [(operator, "+")]
    @test tokenize("?")  == [(operator, "?")]
    @test tokenize("|")  == [(operator, "|")]
    @test tokenize("^")  == [(operator, "^")]
    @test tokenize(raw"$")  == [(operator, raw"$")]
    @test tokenize("a+") == [(character, "a"), (operator, "+")]
    @test tokenize(raw"^test$") == [
      (operator, "^"),
      (character, "t"),
      (concat, ""), 
      (character, "e"),
      (concat, ""),
      (character, "s"),
      (concat, ""),
      (character, "t"),
      (operator, raw"$")
    ]
  end

  @testset "Parentheses" begin
    @test tokenize("(")   == [(left_paren,  "(")]
    @test tokenize(")")   == [(right_paren, ")")]
    @test tokenize("(a)") == [
      (left_paren,  "("),
      (character,   "a"), 
      (right_paren, ")")
    ]
    @test tokenize("(a|b)") == [
      (left_paren,  "("), 
      (character,   "a"), 
      (operator,    "|"), 
      (character,   "b"), 
      (right_paren, ")")
    ]
    @test tokenize("((a) | (b))") == [
      (left_paren,  "("), 
      (left_paren,  "("), 
      (character,   "a"), 
      (right_paren, ")"),
      (concat, ""),
      (character,   " "),
      (operator,    "|"), 
      (character,   " "),
      (concat, ""),
      (left_paren,  "("), 
      (character,   "b"), 
      (right_paren, ")"),
      (right_paren, ")")
    ]
    @test tokenize("(((a)))") == [
      (left_paren,  "("), 
      (left_paren,  "("), 
      (left_paren,  "("), 
      (character,   "a"), 
      (right_paren, ")"),
      (right_paren, ")"),
      (right_paren, ")")
    ]
    @test tokenize("(((a))((b)))") == [
      (left_paren,  "("), 
      (left_paren,  "("), 
      (left_paren,  "("), 
      (character,   "a"), 
      (right_paren, ")"),
      (right_paren, ")"),
      (concat, ""),
      (left_paren,  "("), 
      (left_paren,  "("), 
      (character,   "b"), 
      (right_paren, ")"),
      (right_paren, ")"),
      (right_paren, ")")
    ]
  end

  @testset "Character class" begin
    @test tokenize(raw"[a]")            == [(character_class, "[a]")]
    @test tokenize(raw"[a-z]")          == [(character_class, "[a-z]")]
    @test tokenize(raw"[Aa-zZ]")        == [(character_class, "[Aa-zZ]")]
    @test tokenize(raw"[a-z0-9]")       == [(character_class, "[a-z0-9]")]
    @test tokenize(raw"[a-z0-9A-Z]")    == [(character_class, "[a-z0-9A-Z]")]
    @test tokenize(raw"[a-z0-9A-Z_]")   == [(character_class, "[a-z0-9A-Z_]")]
    @test tokenize(raw"[a-z0-9A-Z_ ]")  == [(character_class, "[a-z0-9A-Z_ ]")]
    @test tokenize(raw"[a-z0-9A-Z_\-]") == [(character_class, "[a-z0-9A-Z_\\-]")]
  end

  @testset "Concatenation" begin
    @test tokenize(raw"ab") == [
      (character, "a"),
      (concat, ""),
      (character, "b")
    ]
    @test tokenize("a b") == [
      (character, "a"),
      (concat, ""),
      (character, " "),
      (concat, ""),
      (character, "b")
    ]
    @test tokenize("a[a-z]") == [
      (character, "a"),
      (concat, ""),
      (character_class, "[a-z]")
    ]
    @test tokenize("a(bc)") == [
      (character, "a"),
      (concat, ""),
      (left_paren, "("),
      (character, "b"),
      (concat, ""),
      (character, "c"),
      (right_paren, ")")
    ]
    @test tokenize("(ab)c") == [
      (left_paren, "("),
      (character, "a"),
      (concat, ""),
      (character, "b"),
      (right_paren, ")"),
      (concat, ""),
      (character, "c")
    ]
    @test tokenize("(ab)[a-z]") == [
      (left_paren, "("),
      (character, "a"),
      (concat, ""),
      (character, "b"),
      (right_paren, ")"),
      (concat, ""),
      (character_class, "[a-z]")
    ]
    @test tokenize("(ab)(cd)") == [
      (left_paren, "("),
      (character, "a"),
      (concat, ""),
      (character, "b"),
      (right_paren, ")"),
      (concat, ""),
      (left_paren, "("),
      (character, "c"),
      (concat, ""),
      (character, "d"),
      (right_paren, ")")
    ]
    @test tokenize("a*b") == [
      (character, "a"),
      (operator, "*"),
      (concat, ""),
      (character, "b")
    ]
    @test tokenize("a|b") == [
      (character, "a"),
      (operator, "|"),
      (character, "b")
    ]
    @test tokenize("a*|b") == [
      (character, "a"),
      (operator, "*"),
      (operator, "|"),
      (character, "b")
    ]
    @test tokenize("a|b*") == [
      (character, "a"),
      (operator, "|"),
      (character, "b"),
      (operator, "*")
    ]
    @test tokenize("a*[a-z]") == [
      (character, "a"),
      (operator, "*"),
      (concat, ""),
      (character_class, "[a-z]")
    ]
    @test tokenize("a*(bc)") == [
      (character, "a"),
      (operator, "*"),
      (concat, ""),
      (left_paren, "("),
      (character, "b"),
      (concat, ""),
      (character, "c"),
      (right_paren, ")")
    ]
    @test tokenize("(ab)*c") == [
      (left_paren, "("),
      (character, "a"),
      (concat, ""),
      (character, "b"),
      (right_paren, ")"),
      (operator, "*"),
      (concat, ""),
      (character, "c")
    ]
    @test tokenize("[a-z]a") == [
      (character_class, "[a-z]"),
      (concat, ""),
      (character, "a")
    ]
    @test tokenize("[a-z][A-Z]") == [
      (character_class, "[a-z]"),
      (concat, ""),
      (character_class, "[A-Z]")
    ]
    @test tokenize("[a-z]*[A-Z]") == [
      (character_class, "[a-z]"),
      (operator, "*"),
      (concat, ""),
      (character_class, "[A-Z]")
    ]
    @test tokenize("[a-z](bc)") == [
      (character_class, "[a-z]"),
      (concat, ""),
      (left_paren, "("),
      (character, "b"),
      (concat, ""),
      (character, "c"),
      (right_paren, ")")
    ]
    @test tokenize(raw"a\$") == [
      (character, "a"),
      (concat, ""),
      (escaped_character, raw"\$")
    ]
    @test tokenize(raw"\$a") == [
      (escaped_character, raw"\$"),
      (concat, ""),
      (character, "a")
    ]
    @test tokenize(raw"\$[a-z]") == [
      (escaped_character, raw"\$"),
      (concat, ""),
      (character_class, "[a-z]")
    ]
    @test tokenize(raw"\$(bc)") == [
      (escaped_character, raw"\$"),
      (concat, ""),
      (left_paren, "("),
      (character, "b"),
      (concat, ""),
      (character, "c"),
      (right_paren, ")")
    ]
    @test tokenize(raw"(ab)\$") == [
      (left_paren, "("),
      (character, "a"),
      (concat, ""),
      (character, "b"),
      (right_paren, ")"),
      (concat, ""),
      (escaped_character, raw"\$")
    ]
    @test tokenize(raw"a*\$") == [
      (character, "a"),
      (operator, "*"),
      (concat, ""),
      (escaped_character, raw"\$")
    ]
    @test tokenize(raw"a*\$[a-z]") == [
      (character, "a"),
      (operator, "*"),
      (concat, ""),
      (escaped_character, raw"\$"),
      (concat, ""),
      (character_class, "[a-z]")
    ]
    @test tokenize(raw"[a-z]\$") == [
      (character_class, "[a-z]"),
      (concat, ""),
      (escaped_character, raw"\$")
    ]
  end
end