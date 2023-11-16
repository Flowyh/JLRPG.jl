function __LEX__main()
  # If the program is run directly, run the main loop
  # Otherwise read path from first argument
  tokens = nothing
  if length(ARGS) == 0
    txt::String = read(stdin, String)
    __LEX__bind_cursor(Cursor(txt; source="stdin"))
    tokens = __LEX__tokenize()
  elseif ARGS[1] == "-h" || ARGS[1] == "--help"
    println("Usage: $(PROGRAM_FILE) [path]")
  elseif !isfile(ARGS[1])
    error("File \"$(ARGS[1])\" does not exist")
  else
    txt = ""
    open(ARGS[1]) do file
      txt = read(file, String)
    end
    __LEX__bind_cursor(Cursor(txt; source=ARGS[1]))
    tokens = __LEX__tokenize()
  end
  @debug "<<<<< LEXER OUTPUT >>>>>"
  @debug "Output tokens: $tokens"

  return __LEX__at_end()
end

if abspath(PROGRAM_FILE) == @__FILE__
  return __LEX__main()
end