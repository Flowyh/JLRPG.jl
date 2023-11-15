function __PAR__usage()
  println("Usage: $(PROGRAM_FILE) [source file]")
end

function __PAR__main()
  # If the program is run directly, run the main loop
  # Otherwise read path from first argument
  tokens = nothing
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
    end
    tokens = __LEX__tokenize(txt)
    __PAR__simulate(tokens, PARSING_TABLE)
  end
  @debug "<<<<< PARSER OUTPUT >>>>>"

  return __PAR__at_end()
end

if abspath(PROGRAM_FILE) == @__FILE__
  return __PAR__main()
end