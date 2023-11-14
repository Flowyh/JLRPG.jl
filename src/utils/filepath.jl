function abspaths(
  paths...
)::AbstractString
  return abspath(joinpath(paths...))
end
