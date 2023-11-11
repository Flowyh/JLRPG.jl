#= SET CONSTRUCTOR =#

Base.Set(args::Vararg) = Set([args...])
Base.Set{T}(args::Vararg{T}) where {T} = Set{T}([args...])

# So... symbols are weird? Without this line Julia will try to infinitely nest a vector within a vector,
# when creating a Set from Varargs containing only ONE symbol (without Set type annotation)
# Example: Set(:a)
Base.Set(please_do_not_explode::Symbol) = Set{Symbol}([please_do_not_explode])

#= SET OPERATIONS =#

Base.setdiff(a::AbstractSet, symbols::Vararg{Symbol}) = setdiff(a, [symbols...])
