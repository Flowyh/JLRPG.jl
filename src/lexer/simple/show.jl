function Base.show(io::IO, token::LexerToken)
  symbol::Symbol = token_symbol(token)
  pos::String = token_file_pos(token)

  print(io, "$(symbol)(")

  if pos != ""
    print(io, "pos=\"$(basename(pos))\"")
  end

  key_values::Vector{String} = []
  for (key, value) in token_values(token)
    push!(key_values, "$(key)=$(value)")
  end

  if length(key_values) > 0
    print(io, ", ")
  end

  print(io, join(key_values, ", "))
  print(io, ")")
end

function show_simple(io::IO, token::LexerToken)
  symbol::Symbol = token_symbol(token)
  print(io, "$(symbol)(")

  key_values::Vector{String} = []
  for (key, value) in token_values(token)
    push!(key_values, "$(key)=$(value)")
  end

  print(io, join(key_values, ", "))
  print(io, ")")
end
