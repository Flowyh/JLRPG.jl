# <<: usage start :>>
function __PAR__usage()
  println("Usage: $(PROGRAM_FILE) [source file]")
end
# <<: usage end :>>

# <<: main start :>>
function __PAR__main()
  if length(ARGS) != 1
    return __PAR__usage()
  elseif ARGS[1] == "-h" || ARGS[1] == "--help"
    return __PAR__usage()
  elseif !isfile(ARGS[1])
    error("File \"$(ARGS[1])\" does not exist")
  else
    txt = ""
    open(ARGS[1]) do file
      txt = read(file, String)
      __LEX__bind_cursor(Cursor(txt; source=ARGS[1]))
    end
    # Tokenize
    tokens = nothing
    try
      tokens = __LEX__tokenize()
    catch e
      e = ErrorException(replace(e.msg, r"\n       " => "\n"))
      @error "Error while tokenizing input" exception=(e, catch_backtrace())
      exit(1)
    end
    # Parse
    try
      __PAR__simulate(tokens)
    catch e
      if e isa ErrorException
        e = ErrorException(replace(e.msg, r"\n       " => "\n"))
        @error "Error while parsing tokens" exception=(e, catch_backtrace())
        exit(1)
      end
      @error "Error while parsing tokens" exception=(e, catch_backtrace())
    end
  end
  @debug "<<<<< PARSER OUTPUT >>>>>"

  return __PAR__at_end()
end
# <<: main end :>>

if abspath(PROGRAM_FILE) == @__FILE__
  return __PAR__main()
end