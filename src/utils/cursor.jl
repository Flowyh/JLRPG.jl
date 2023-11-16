module Cursors
  export Cursor
  export cursor_is_eof
  export cursor_move
  export cursor_findnext, cursor_findnext_and_move
  export cursor_match
  export cursor_slice, cursor_rest, cursor_at
  export cursor_file_position
  export cursor_error

  mutable struct Cursor
    txt::String
    txt_length::Int
    cursor::Int
    line::Int
    column::Int
    source::String

    function Cursor(txt::String; source="", unexpand_home=true)
      if unexpand_home
        source = replace(source, expanduser("~") => "~")
      end
      new(txt, length(txt), 1, 1, 0, source)
    end
  end

  function cursor_is_eof(c::Cursor)::Bool
    return c.cursor > c.txt_length
  end

  function cursor_move(c::Cursor, matched_text::String)::Nothing
    lines = count("\n", matched_text)
    last_newline::Int = 0
    c.column += length(matched_text)
    if lines > 0
      last_newline = findlast("\n", matched_text).stop
      c.column = length(matched_text[last_newline:end])
    end
    c.cursor += length(matched_text)
    c.line += lines

    nothing
  end

  function cursor_findnext(
    c::Cursor,
    pattern::Regex
  )::Union{Nothing, UnitRange{Int}}
    matched::Union{Nothing, UnitRange{Int}} = findnext(pattern, c.txt, c.cursor)
    if matched === nothing || matched.start != c.cursor
      return nothing
    end
    return matched
  end

  function cursor_findnext_and_move(
    c::Cursor,
    pattern::Regex
  )::Union{Nothing, UnitRange{Int}}
    matched = cursor_findnext(c, pattern)
    if matched === nothing
      return nothing
    end
    cursor_move(c, c.txt[matched])
    return matched
  end

  function cursor_match(
    c::Cursor,
    pattern::Regex;
    slice::Union{Nothing, UnitRange{Int}} = nothing
  )::Union{Nothing, RegexMatch}
    if slice === nothing
      return match(pattern, c.txt[c.cursor:end])
    end
    return match(pattern, c.txt[slice])
  end

  function cursor_slice(c::Cursor, slice::UnitRange{Int})::String
    return c.txt[slice]
  end

  function cursor_rest(c::Cursor)::String
    return c.txt[c.cursor:end]
  end

  function cursor_at(c::Cursor)::AbstractChar
    return c.txt[c.cursor]
  end

  function cursor_file_position(c::Cursor)::String
    return c.source * ":$(c.line):$(c.column)"
  end

  function cursor_error(
    c::Cursor,
    error_msg::String;
    erroneous_slice::Union{Nothing, UnitRange{Int}} = nothing
  )::String
    if erroneous_slice === nothing
      erroneous_slice = c.cursor:c.cursor
    end
    error(
      "$error_msg" * "\n" * 
      "       \"$(cursor_slice(c, erroneous_slice))\" at $(cursor_file_position(c))"
    )
  end
end
