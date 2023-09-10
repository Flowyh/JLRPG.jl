module JLPG
  using Reexport

  include("regex/Regex.jl")
  @reexport using .JLPG_Regex
end
