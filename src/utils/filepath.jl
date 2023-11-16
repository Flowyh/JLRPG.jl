function abspaths(
  paths...
)::AbstractString
  return abspath(joinpath(paths...))
end

function unexpanduser(
  path::String
)
  return replace(path, expanduser("~") => "~")
end
