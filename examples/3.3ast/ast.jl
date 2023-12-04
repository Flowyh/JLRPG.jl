abstract type Node end

struct Num <: Node
  value::Operand
end

struct Add <: Node
  left::Node
  right::Node
end

struct Sub <: Node
  left::Node
  right::Node
end

struct Mul <: Node
  left::Node
  right::Node
end

struct Div <: Node
  left::Node
  right::Node
end

eval(n::Num)::Operand = n.value
eval(n::Add)::Operand = add(eval(n.left), eval(n.right))
eval(n::Sub)::Operand = sub(eval(n.left), eval(n.right))
eval(n::Mul)::Operand = mul(eval(n.left), eval(n.right))
eval(n::Div)::Operand = div(eval(n.left), eval(n.right))
