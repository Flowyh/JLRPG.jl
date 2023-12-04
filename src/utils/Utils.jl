module JLPG_Utils
  using Reexport

  include("filepath.jl")
  export abspaths, unexpanduser

  include("comparable.jl")
  export Comparable

  include("convert_type.jl")
  export convert_type

  include("set_extensions.jl")

  include("regexes.jl")
  export full_function_pattern, function_definition, function_name

  include("cursor.jl")
  @reexport using .Cursors
end
