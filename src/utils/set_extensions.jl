Base.Set{T}(args::Vararg{T}) where {T} = Set{T}([args...])
Base.Set(args::Vararg) = Set([args...])
