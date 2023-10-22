abstract type Comparable end

function Base.:(==)(a::T, b::T) where T <: Comparable
  f = fieldnames(T)
  getfield.(Ref(a),f) == getfield.(Ref(b),f)
end
