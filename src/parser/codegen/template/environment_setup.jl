using JLPG

if isfile("__LEX__.jl")
  include("__LEX__.jl")
else
  @debug "Default __LEX__.jl file not found at current directory."
  @debug "Put generated __LEX__.jl file at current directory or include it at top of the definitions section in your grammar file."
end

mutable struct __PAR__vars
  # TODO: Fill if needed
end

function __PAR__at_end()
  return false
end