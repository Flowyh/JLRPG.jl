function from_current_path(
  root = @__DIR__,
  paths...
)::String
  return abspath(joinpath(root, paths...))
end
