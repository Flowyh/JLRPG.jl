module JLPG_Utils
  include("filepath.jl")
  export from_current_path

  include("comparable.jl")
  export Comparable

  include("convert_type.jl")
  export convert_type

  include("set_extensions.jl")
end
