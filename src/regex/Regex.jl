module JLPG_Regex
  include("types.jl")
  export NothingNode, End, Character, CharacterClass, Concatenation, Alternation, KleeneStar, AtLeastOne, Optional
  
  include("tokenize.jl")
  for op in instances(Operator)
    @eval export $(Symbol(op))
  end
  for token in instances(Token)
    @eval export $(Symbol(token))
  end
  export tokenize
end