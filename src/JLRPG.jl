module JLRPG
  using Reexport

  include("utils/Utils.jl")
  @reexport using .JLRPG_Utils

  include("regex/Regex.jl")
  @reexport using .JLRPG_Regex

  include("lexer/simple/SimpleLexer.jl")
  @reexport using .JLRPG_SimpleLexer

  include("parser/Parser.jl")
  @reexport using .JLRPG_Parser
end
