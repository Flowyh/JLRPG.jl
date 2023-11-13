convert_type(::Type{String}, val) = val isa String ? val : repr(val)
convert_type(::Type{AbstractChar}, val) = only("$val")
convert_type(::Type{Char}, val) = only("$val")

for numeric in (:Int, :Int8, :Int16, :Int32, :Float16, :Float32, :Float64)
  @eval convert_type(::Type{$numeric}, val) = val isa Number ? $numeric(val) : parse($numeric, val)
end

function convert_type(::Type{Symbol}, val)
  return Symbol(val)
end
