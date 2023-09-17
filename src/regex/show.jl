# === AST === 

# === Stats ===

function Base.show(io::IO, s::NodeStats)
  print(io, "Stats($(s.nullable), $(s.firstpos), $(s.lastpos))")
end

# === Leaves ===

function Base.show(io::IO, e::End)
  print(io, "End($(e.pattern), :$(e.token), $(e.position), $(e.stats), :$(e.action))")
end

function Base.show(io::IO, c::Character)
  print(io, "Character($(c.char), $(c.position), $(c.stats))")
end

function Base.show(io::IO, c::PossibleCharacters)
  print(io, "PossibleCharacters($(c.chars), $(c.position), $(c.stats))")
end

# === Operators ===

function Base.show(io::IO, c::Concatenation)
  print(io, "Concatenation[$(c.left), $(c.right), $(c.stats)]")
end

function Base.show(io::IO, a::Alternation)
  print(io, "Alternation[$(a.left), $(a.right), $(a.stats)]")
end

function Base.show(io::IO, k::KleeneStar)
  print(io, "KleeneStar[$(k.child), $(k.stats)]")
end

function Base.show(io::IO, a::AtLeastOne)
  print(io, "AtLeastOne[$(a.child), $(a.stats)]")
end

function Base.show(io::IO, o::Optional)
  print(io, "Optional[$(o.child), $(o.stats)]")
end
