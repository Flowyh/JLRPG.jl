# Abstract arithmetic type
abstract type Operand end

add(a::Operand, b::Operand)::Operand = a + b
sub(a::Operand, b::Operand)::Operand = a - b
mul(a::Operand, b::Operand)::Operand = a * b
div(a::Operand, b::Operand)::Operand = a / b

# Galois field calculator of order P
struct GF{P} <: Operand
  value::Int
  function GF{P}(value::Int) where {P}
    return new(mod(value, P))
  end
end

(Base.:+)(a::GF{P}, b::GF{P}) where P = GF{P}(a.value + b.value)
(Base.:-)(a::GF{P}, b::GF{P}) where P = GF{P}(a.value - b.value)
(Base.:*)(a::GF{P}, b::GF{P}) where P = GF{P}(a.value * b.value)
(Base.:/)(a::GF{P}, b::GF{P}) where P = GF{P}(a.value * invmod(b.value, P))

Base.show(io::IO, a::GF{P}) where P = print(io, "GaloisField{order: $P}($(a.value))")
