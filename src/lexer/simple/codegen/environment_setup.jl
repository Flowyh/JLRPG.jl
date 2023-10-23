using JLPG

mutable struct __LEX__vars
  current_match::String
  line::Int
  column::Int
end

__LEX__ = __LEX__vars("", -1, -1)

function __LEX__current_match(new_match)
  __LEX__.current_match = new_match
end

function __LEX__line(new_line)
  __LEX__.line = new_line
end

function __LEX__column(new_column)
  __LEX__.column = new_column
end

function __LEX__at_end()
  return __LEX__.current_match == ""
end