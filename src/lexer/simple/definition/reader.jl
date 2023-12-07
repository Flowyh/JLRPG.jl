using Parameters: @consts

@enum LexerSection definitions actions code
@enum LexerSpecialDefinition section code_block option regex_alias action comment

@consts begin
  LexerSectionDelimiter::String = "%%"
  LexerCodeBlockStart::String = "%{"
  LexerCodeBlockEnd::String = "%}"

  LEXER_SECTION_REGEX = r"%%"
  LEXER_CODE_BLOCK_REGEX = r"%{((?s:.)*?)%}"
  LEXER_KW_OPTION_REGEX = r"%option[ \t]+(?<name>\w+)=\"(?<value>\w+)\""
  LEXER_OPTION_REGEX = r"%option[ \t]+(?<value>\w+)"
  REGEX_ALIAS_REGEX = r"(?<name>[A-Z0-9_-]+)\s+(?<pattern>.+)"
  ACTION_REGEX = r"(?<pattern>.+?)\s+:{(?<body>(?s:.)+?)}:"
  LEXER_COMMENT_REGEX = r"#=[^\n]*=#"

  SpecialDefinitionPatterns::Vector{Pair{LexerSpecialDefinition, Regex}} = [
    section => LEXER_SECTION_REGEX,
    code_block => LEXER_CODE_BLOCK_REGEX,
    comment => LEXER_COMMENT_REGEX,
    regex_alias => REGEX_ALIAS_REGEX,
    option => LEXER_KW_OPTION_REGEX,
    option => LEXER_OPTION_REGEX,
    action => ACTION_REGEX,
  ]
end

# Structure of a definition file:
#
# definitions/flags/regex aliases
# %%
# lexer actions
# %%
# user code
#
# Blocks enclosed with %{ and %} are copied to the output file (in the same order).

"""
    read_lexer_definition_file(path::String)::Lexer

Read lexer definition file from `path` and construct a `Lexer` object.

The syntax for lexer definition files follow the same syntax as [Flex](https://westes.github.io/flex/manual/) definition files.

# Definition file structure
Lexer definition file consists of three sections:
  - Definitions section, where regex aliases and lexer options are defined.
  - Actions section, where lexer actions are defined.
  - Code section, where user code is defined.

Each section is separated by a `%%` delimiter.

# Definitions section
Definitions section consists of regex aliases and lexer options.
Regexes should conform to the [PCRE](https://www.pcre.org/) syntax, since Julia uses PCRE regexes.

## Regex aliases
Regex aliases are defined as follows:
```
ALIAS_NAME REGEX
```
where `ALIAS_NAME` is a name of the alias and `REGEX` is a regex pattern.

Regex aliases can be referenced in other regexes by using `{ALIAS_NAME}` syntax.
If an alias is referenced before it is defined, an error will be thrown.

## Lexer options
Currently there's only one lexer option available: `tag`.
This option allows renaming of the prefix of all objects generated in the lexer.
This includes all token definitions, special functions, etc.

The `tag` option is defined as follows:
```
%option tag="TAG_NAME"
```
where `TAG_NAME` is the new prefix.

Renaming the lexer tag will also rename the default name of the generated lexer file.
For example, if the tag is set to `MyLexer`, the generated lexer file will be
named `MyLexer.jl`. Keep in mind, that a generated parser requires `__LEX__.jl` file to
be present in the same directory. If no such file is found, it is required that the user
includes it by themselves using in a code block/section.

# Actions section
Actions section consists of lexer actions.
Each lexer action is defined as follows:
```
PATTERN :{ ACTION_BODY }:
```
where `PATTERN` is a regex pattern and `ACTION_BODY` is a Julia code block.

The `PATTERN` is matched against the input text.
If the match is successful, the `ACTION_BODY` is executed.
The `ACTION_BODY` should return a token object, but it is not required.

## Action patterns
Action patterns are constructed using one or many pattern parts: regexes,
aliases or literal strings. Patterns should not be separated by whitespace,
since it is treated as a literal whitespace character. Literal strings are strings
enclosed in double quotes (`"`). They are treated as a sequence of characters,
not as a regex. Regexes are defined using the PCRE syntax.

For example:
```
"hello"{ALIAS_NAME}[0-9]+
```
is a valid pattern definition, which will be later converted to a single regex.

## Action tokens
Each action body may return a token object using the `return` keyword. There is no
need to predefine token types, since they are generated automatically by
`retrieve_tokens_from_actions` function.

Tokens are defined as follows:
```
return TOKEN_NAME(ARGUMENTS)
```
where `TOKEN_NAME` is a name of the token and `ARGUMENTS` is a list of arguments.
Arguments may be named and typed, but it is not required. See: `retrieve_tokens_from_actions` for more information.

# Code section
Code section consists of user code. It is copied to the output file as is, in the same
order as it was defined in the definition file.

Additionally the user may define code blocks enclosed with `%{` and `%}`,
which will be also copied to the output file.
Code blocks may be inserted in all of the sections, but they should not be intermixed
with other definition file constructs (such as action patterns, action bodies, etc.).

# Commenting
Comments are defined using the `#=` and `=#` delimiters. Comments are single-line only.
They should not be mixed with other definition file constructs.

# Example
For valid lexer definition files examples see the `examples` directory.
"""
function read_lexer_definition_file(
  path::String
)::Lexer
  lexer::Union{Nothing, Lexer} = nothing
  open(path) do file
    text::String = read(file, String)
    c::Cursor = Cursor(text; source=path)
    lexer = _read_lexer_definition_file(c)
  end

  return lexer::Lexer
end

function _next_lexer_section(
  current::LexerSection
)::LexerSection
  if current == definitions
    return actions
  elseif current == actions
    return code
  end
end

function _lexer_section_guard(
  current::LexerSection,
  expected::LexerSection,
  c::Cursor,
  err_msg::String;
  erroneous_slice::Union{Nothing, UnitRange{Int}} = nothing
)
  if current != expected
    cursor_error(c, err_msg; erroneous_slice=erroneous_slice)
  end
end

function _read_lexer_definition_file(
  c::Cursor
)::Lexer
  current_section = definitions
  aliases::Vector{RegexAlias} = []
  lexer_actions::Vector{LexerAction} = []
  options = Dict()
  code_blocks::Vector{String} = []

  while !cursor_is_eof(c)
    did_match::Bool = false

    for (definition, pattern) in SpecialDefinitionPatterns
      matched = cursor_findnext_and_move(c, pattern)
      if matched === nothing
        continue
      end
      m = cursor_match(c, pattern; slice=matched)

      if definition == section
        current_section = _next_lexer_section(current_section)
      elseif definition == code_block
        code_block_txt = cursor_slice(c, matched)
        push!(code_blocks, strip(code_block_txt[4:end-2])) # Omit %{\n and %}
      elseif definition == option
        _lexer_section_guard(
          current_section,
          definitions,
          c, "Option outside of definitions section";
          erroneous_slice=matched
        )
        if haskey(m, :name) # KW option
          if m[:name] == "tag"
            options[:tag] = m[:value]
          end
        else
          # TODO: Fill options if needed
        end
      elseif definition == regex_alias
        _lexer_section_guard(
          current_section,
          definitions,
          c, "Regex alias outside of definitions section";
          erroneous_slice=matched
        )
        push!(aliases, RegexAlias(
          Symbol(m[:name]),
          m[:pattern]
        ))
      elseif definition == action
        _lexer_section_guard(
          current_section,
          actions,
          c, "Action outside of actions section";
          erroneous_slice=matched
        )

        if any(action -> action.pattern == m[:pattern], lexer_actions)
          cursor_error(
            c, "Redefined action pattern";
            erroneous_slice=matched
          )
        end

        push!(lexer_actions, LexerAction(
          m[:pattern],
          strip(m[:body])
        ))
      end

      did_match = true
      break
    end

    if current_section == code && !isempty(strip(cursor_rest(c)))
      to_copy = cursor_rest(c)
      # Remove comments
      for m in eachmatch(LEXER_COMMENT_REGEX, to_copy)
        to_copy = replace(to_copy, m.match => "")
      end

      # Copy everything
      push!(code_blocks, strip(to_copy))
      break
    end

    # Omit whitespace
    whitespace = cursor_findnext_and_move(c, r"[\r\t\f\v\n ]+")
    if whitespace !== nothing
      did_match = true
    end

    if !did_match
      cursor_error(c, "Invalid character/s in definition file")
    end
  end

  if current_section != code
    error("Invalid definition file, not enough sections")
  end

  return Lexer(
    lexer_actions,
    aliases,
    code_blocks,
    LexerOptions(options)
  )
end

#============#
# PRECOMPILE #
#============#
precompile(read_lexer_definition_file, (
  String,
))
precompile(_next_lexer_section, (
  LexerSection,
))
precompile(_lexer_section_guard, (
  LexerSection,
  LexerSection,
  Cursor,
  String,
))
precompile(_read_lexer_definition_file, (
  Cursor,
))
