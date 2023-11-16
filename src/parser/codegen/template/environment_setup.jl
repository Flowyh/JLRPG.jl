using JLPG

if isfile("__LEX__.jl")
  include("__LEX__.jl")
else
  @debug "Default __LEX__.jl file not found at current directory."
  @debug "Put generated __LEX__.jl file at current directory or include it at top of the definitions section in your grammar file."
end

mutable struct __PAR__vars
  c::Union{Nothing, Cursor}
end

function Base.getproperty(::__PAR__vars, ::Symbol)
  error("__PAR__vars cannot be accessed directly")
end

function Base.setproperty!(:: __PAR__vars, ::Symbol, _)
  error("__PAR__vars cannot be accessed directly")
end

# Using const allows throwing a warning when redefining __PAR__
const __PAR__ = __PAR__vars(nothing)

function __PAR__bind_cursor(c::Cursor)
  setfield!(__PAR__, :c, c)
end

function __PAR__cursor()::Union{Nothing, Cursor}
  return getfield(__PAR__, :c)
end

function __PAR__at_end()
  return false
end