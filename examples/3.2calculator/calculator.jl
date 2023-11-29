abstract type Operand end

function add(a::Operand, b::Operand)::Operand
  return a + b
end

function sub(a::Operand, b::Operand)::Operand
  return a - b
end

function mul(a::Operand, b::Operand)::Operand
  return a * b
end

function div(a::Operand, b::Operand)::Operand
  return a / b
end

struct Number <: Operand
  value::Int
end

(Base.:+)(a::Number, b::Number) = Number(a.value + b.value)
(Base.:-)(a::Number, b::Number) = Number(a.value - b.value)
(Base.:*)(a::Number, b::Number) = Number(a.value * b.value)
(Base.:/)(a::Number, b::Number) = Number(round(a.value / b.value))

function main()
  # Test operations
  a = Number(1)
  b = Number(2)
  println(a + b)
  println(a - b)
  println(a * b)
  println(a / b)
  println(add(a, b))
  println(sub(a, b))
  println(mul(a, b))
  println(div(a, b))
end

main()

struct GaloisField{P} <: Number
  value::Int

  function GaloisField{P}(value::Int) where {P}
    return new(mod(value, P))
  end
end

(Base.:+)(a::GaloisField{P}, b::GaloisField{P}) where P = GaloisField{P}(a.value + b.value)
(Base.:-)(a::GaloisField{P}, b::GaloisField{P}) where P = GaloisField{P}(a.value - b.value)
(Base.:*)(a::GaloisField{P}, b::GaloisField{P}) where P = GaloisField{P}(a.value * b.value)
(Base.:/)(a::GaloisField{P}, b::GaloisField{P}) where P = GaloisField{P}(a.value * invmod(b.value, P))