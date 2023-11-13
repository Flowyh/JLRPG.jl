#=== START OF ENVIRONEMNT SETUP ===#
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
#===   END OF ENVIRONEMNT SETUP ===#

#=== START OF CODE BLOCKS DEFINED IN LEXER (INSERTED IN ORDER OF DEFINITION)===#
#===   END OF CODE BLOCKS DEFINED IN LEXER (INSERTED IN ORDER OF DEFINITION)===#

#=== START OF TOKENS RETURNED BY LEXER ACTIONS ===#
#<<<: DECL Char :>>>#
struct Char <: LexerToken
  tag::Symbol
  values::Dict
end

function Char(;char::AbstractChar, )::Char
  return Char(
    :Char,
    Dict(:char => char,)
  )
end
#<<<: EODL Char :>>>#

#<<<: DECL Id :>>>#
struct Id <: LexerToken
  tag::Symbol
  values::Dict
end

function Id(;value::String, )::Id
  return Id(
    :Id,
    Dict(:value => value,)
  )
end
#<<<: EODL Id :>>>#

#<<<: DECL Number :>>>#
struct Number <: LexerToken
  tag::Symbol
  values::Dict
end

function Number(;val::Int, )::Number
  return Number(
    :Number,
    Dict(:val => val,)
  )
end
#<<<: EODL Number :>>>#

#<<<: DECL Error :>>>#
struct Error <: LexerToken
  tag::Symbol
  values::Dict
end

function Error(;char::AbstractChar, )::Error
  return Error(
    :Error,
    Dict(:char => char,)
  )
end
#<<<: EODL Error :>>>#
#===   END OF TOKENS RETURNED BY LEXER ACTIONS ===#

#=== START OF ACTIONS ===#
#<<<: [ \t\r\n]+ >>>#
function action1()::Union{LexerToken, Any}
   # Ignore 
end

#<<< PATTERN TO ACTION FUNCTION MAPPINGS >>>##<<<: '[a-zA-Z]' >>>#
function action2()::Union{LexerToken, Any}
  
  println("Got a Char! ", __LEX__.current_match)
  return Char(;char=convert_type(AbstractChar, __LEX__.current_match[2]))

end

#<<< PATTERN TO ACTION FUNCTION MAPPINGS >>>##<<<: [_a-zA-Z]([_a-zA-Z]|[0-9])+ >>>#
function action3()::Union{LexerToken, Any}
  
  println("Got an Id! ", __LEX__.current_match)
  return Id(;value=convert_type(String, __LEX__.current_match))

end

#<<< PATTERN TO ACTION FUNCTION MAPPINGS >>>##<<<: [0-9]+ >>>#
function action4()::Union{LexerToken, Any}
  
  println("Got a Number! ", __LEX__.current_match)
  return Number(;val=convert_type(Int, __LEX__.current_match))

end

#<<< PATTERN TO ACTION FUNCTION MAPPINGS >>>##<<<: . >>>#
function action5()::Union{LexerToken, Any}
   return Error(;char=convert_type(AbstractChar, __LEX__.current_match)) 
end

#<<< PATTERN TO ACTION FUNCTION MAPPINGS >>>#
const PATTERN_TO_ACTION = Dict(
  r"[ \t\r\n]+" => action1, 
  r"'[a-zA-Z]'" => action2, 
  r"[_a-zA-Z]([_a-zA-Z]|[0-9])+" => action3, 
  r"[0-9]+" => action4, 
  r"." => action5
)
#===   END OF ACTIONS ===#

#=== START OF TOKENIZE LOOP ===#
const ACTION_PATTERNS = [
  r"[ \t\r\n]+", 
  r"'[a-zA-Z]'", 
  r"[_a-zA-Z]([_a-zA-Z]|[0-9])+", 
  r"[0-9]+", 
  r"."
]

function __LEX__tokenize(txt::String)::Vector{LexerToken}
  @debug "<<<<<: START OF TOKENIZE :>>>>>"
  tokens::Vector{LexerToken} = []
  cursor::Int = 1
  while cursor <= length(txt)
    did_match::Bool = false
    for pattern in ACTION_PATTERNS
      matched = findnext(pattern, txt, cursor)
      if matched === nothing || matched.start != cursor
        continue
      end
      @debug "New match of length $(length(matched)) found: $(txt[matched])"
      __LEX__current_match(txt[matched])

      token = PATTERN_TO_ACTION[pattern]()
      if token isa LexerToken
        @debug "New token has been created: $token"
        push!(tokens, token)
      end

      did_match = true
      cursor += length(matched)
      break
    end

    if !did_match
      error("Syntax error, cannot match remaining text: $(txt[cursor:end])")
    end
  end

  @debug "<<<<<:   END OF TOKENIZE :>>>>>"
  return tokens
end
#===   END OF TOKENIZE LOOP ===#

#=== START OF MAIN FUNCTION ===#
function main()
  # If the program is run directly, run the main loop
  # Otherwise read path from first argument
  tokens = nothing
  if length(ARGS) == 0
    txt::String = read(stdin, String)
    tokens = __LEX__tokenize(txt)
  elseif ARGS[1] == "-h" || ARGS[1] == "--help"
    println("Usage: $(PROGRAM_FILE) [path]")
  elseif !isfile(ARGS[1])
    error("File \"$(ARGS[1])\" does not exist")
  else
    txt = ""
    open(ARGS[1]) do file
      txt = read(file, String)
    end
    tokens = __LEX__tokenize(txt)
  end
  @debug "<<<<<: LEXER OUTPUT :>>>>>"
  @debug "Output tokens: $tokens"

  return __LEX__at_end()
end

if abspath(PROGRAM_FILE) == @__FILE__
  return main()
end
#===   END OF MAIN FUNCTION ===#
