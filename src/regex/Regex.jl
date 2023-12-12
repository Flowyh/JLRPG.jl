module JLRPG_Regex
  include("ast.jl")
  include("pos_functions.jl")
  export RegexNode
  export End, Character, PossibleCharacters, Concatenation, Alternation, KleeneStar, AtLeastOne, Optional
  export doNothing
  export NodeStats, nullable, firstpos, lastpos, followpos
  
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
  export CharsetToAllCharacters

  include("show.jl")
end
