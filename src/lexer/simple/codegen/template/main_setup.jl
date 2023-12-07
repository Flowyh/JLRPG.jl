function __LEX__usage()
  println("Usage: $(PROGRAM_FILE) [source file]")
end

function __LEX__main()
  # If the program is run directly, run the main loop
  # Otherwise read path from first argument
  tokens = nothing
  if length(ARGS) == 0
    txt::String = read(stdin, String)
    __LEX__bind_cursor(Cursor(txt; source="stdin"))
    tokens = __LEX__tokenize()
  elseif ARGS[1] == "-h" || ARGS[1] == "--help"
    return __LEX__usage()
  elseif !isfile(ARGS[1])
    error("File \"$(ARGS[1])\" does not exist")
  else
    txt = ""
    open(ARGS[1]) do file
      txt = read(file, String)
      __LEX__bind_cursor(Cursor(txt; source=ARGS[1]))
    end
    try
      tokens = __LEX__tokenize()
    catch e
      e = ErrorException(replace(e.msg, r"\n       " => "\n"))
      @error "Error while tokenizing input" exception=(e, catch_backtrace())
      exit(1)
    end
  end
  @debug "<<<<< LEXER OUTPUT >>>>>"
  @debug "Output tokens: $tokens"

  return __LEX__at_end()
end

if abspath(PROGRAM_FILE) == @__FILE__
  return __LEX__main()
end