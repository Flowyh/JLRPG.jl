using JLPG

mutable struct __LEX__vars
  c::Union{Nothing, Cursor}
  current_match::String
  file_pos_before_match::String
end

function Base.getproperty(::__LEX__vars, ::Symbol)
  error("__LEX__vars cannot be accessed directly")
end

function Base.setproperty!(:: __LEX__vars, ::Symbol, _)
  error("__LEX__vars cannot be accessed directly")
end

# Using const allows throwing a warning when redefining __LEX__
const __LEX__ = __LEX__vars(nothing, "", "")

function __LEX__bind_cursor(c::Cursor)
  setfield!(__LEX__, :c, c)
end

function __LEX__cursor()::Union{Nothing, Cursor}
  return getfield(__LEX__, :c)
end

function __LEX__set_current_match(new_match::String)
  setfield!(__LEX__, :current_match, new_match)
end

function __LEX__current_match()::String
  return getfield(__LEX__, :current_match)
end

function __LEX__set_file_pos_before_match(new_pos::String)
  setfield!(__LEX__, :file_pos_before_match, new_pos)
end

function __LEX__file_pos_before_match()::String
  return getfield(__LEX__, :file_pos_before_match)
end

function __LEX__at_end()
  return false
end