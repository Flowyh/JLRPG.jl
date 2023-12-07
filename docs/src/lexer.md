# SimpleLexer definition files

The first step of creating a proper parser is to define a lexer. JLPG.jl supports generation of simplified lexer files, which rely on Julia's regex engine (PCRE2 standard).

Customarily, lexer definition files have `.jlex` extension.

Lexer definition files consist of three sections:

- **definitions** - in this section regex aliases and lexer options should be defined.
- **actions** - lexer actions are defined here.
- **code** - user defined code that will be copied into the generated lexer file might be placed here.

## Definitions

Definitions section is optional. It consists of regex aliases and lexer options.

### Regex aliases

Regex aliases are defined in the following way:

```
ALIAS_NAME REGEX
```

where `ALIAS_NAME` is the name of the alias and `REGEX` is the PCRE2 conformant regex that will be aliased. Regex aliases can be used in lexer actions or other regex aliases.

To use a regex alias the following syntax should be used:

```
{ALIAS_NAME}
```

### %option

Lexer options are defined in the following way:

```
%option OPTION_NAME
%option KEYWORD_OPTION_NAME=VALUE
```

where `OPTION_NAME` or `KEYWORD_OPTION_NAME` is the name of the option and `VALUE` is the value of the option. Lexer options can be used to change the behaviour of the lexer.

Currently there's only one lexer option available:

```
%option tag=TAG_NAME
```

It allows to change the prefix of all generated object names. By default it is set to `__LEX__`.

## Actions

Actions section is required. It consists of lexer actions.

Lexer actions are defined in the following way:

```
PATTERN :{ ACTION }:
```

where `PATTERN` may consist of three different parts:

- normal regex pattern
- regex aliases
- literal strings enclosed in double quotes, they are treated as normal characters (useful for matching special regex characters, like `*`, `+`, `?`, etc.)

`ACTION` is a Julia code that will be executed when the pattern is matched. It may consist of multiple lines of code, but it must be enclosed in special delimiters: `:{` and `}:`.

### Returning tokens from lexer actions

Lexer actions may return a token, which will be later passed to the parser. To return a token, the following syntax should be used:

```
return Token(parameters...)
```

where `Token` is the name of the token type and `parameters...` are the parameters that will be passed to the token constructor. Parameters may be named and typed, but it is not required.

If a token argument is not typed, it is assumed to be of type `String`.

### Token parameters naming rules

Parameter naming rules are as follows:

- If a token has only one argument and it is not named, then it's name is `value`.
- If a token has more than one argument and they are not named, the their name are `value1`, `value2`, ..., `valueN`, where `N` is the position of the argument.
- If an argument is named, then it is accessible by it's name.

There's no need to define a tokens type before using it in a lexer action. All actions are scanned during the definition file analysis and all tokens types are automatically generated.

### Referencing the current matched string

To reference the current matched string, double dollar sign syntax should be used, for example:

```
{NUMBER}                 :{
  val::Int = parse(Int, $$)
  return Number(::Int=val)
}:
```

In this example, the currently matched number text is parsed into an integer and then passed to the `Number` token constructor.

## Code

Code section is optional. It consists of user defined code that will be pasted into the generated lexer file.

### Additional code blocks

Additionally, the user can insert additional code blocks into the definition file using the following delimiters:

```
%{
...
%}
```

Be mindful that the code blocks should not be intermixed with other definition file constructs (e.g. lexer options, regex aliases, etc.).

## Comments

Comments in lexer definition files are single-line and are enclosed by special delimiters:

```
#= ... =#
```

Comments should not be mixed with other definition file constructs (e.g. lexer options, regex aliases, etc.).

## Special function overloading

Some special functions in the generated lexer file can be overloaded by the user. The following functions can be overloaded:

- `__LEX__at_end()` - this function is run after the lexer has finished tokenizing the input. By default it returns `false` as an indicator of success.
- `__LEX__main()` - this function is run when the lexer is run directly from the command line. By default it either reads the input from the standard input or from the file specified as the first command line argument and then tokenizes it.
- `__LEX__usage()` - used to print the helper usage message when the lexer is run incorrectly from the command line. By default it prints the following message:
  ```
  Usage: $(PROGRAM_FILE) [source file]
  ```

To overload a function, just define it in the code section/block of the lexer definition file.

## Valid lexer definition files examples

See [Examples](@ref) for valid lexer definition files examples.
