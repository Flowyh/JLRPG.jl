module JLPG_Regex
  include("ast.jl")
  export NothingNode, End, Character, CharacterClass, Concatenation, Alternation, KleeneStar, AtLeastOne, Optional
  export doNothing
  
  include("tokenize.jl")
  for token in instances(Token)
    @eval export $(Symbol(token))
  end
  export tokenize

  include("treeify.jl")
  for op in instances(Operator)
    @eval export $(Symbol(op))
  end
  export treeify

  include("show.jl")
end