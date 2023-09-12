# === AST === 

function Base.show(io::IO, e::End)
  print(io, "End($(e.pattern), :$(e.token), :$(e.action))")
end

function Base.show(io::IO, c::Character)
  print(io, "Character($(c.char))")
end

function Base.show(io::IO, c::PossibleCharacters)
  print(io, "PossibleCharacters($(c.chars))")
end

function Base.show(io::IO, c::Concatenation)
  print(io, "Concatenation[$(c.left), $(c.right)]")
end

function Base.show(io::IO, a::Alternation)
  print(io, "Alternation[$(a.left), $(a.right)]")
end

function Base.show(io::IO, k::KleeneStar)
  print(io, "KleeneStar[$(k.child)]")
end

function Base.show(io::IO, a::AtLeastOne)
  print(io, "AtLeastOne[$(a.child)]")
end

function Base.show(io::IO, o::Optional)
  print(io, "Optional[$(o.child)]")
end