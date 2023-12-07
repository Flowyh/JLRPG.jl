# Parser definition files

The main purpose of this package is to generate LR parsers from Bison-like parser definition files.

Customarily, lexer definition files have `.jlex` extension.

The parser definition files consist of three sections:

- **definitions** - in this section tokens, nonterminal types and options should be defined.
- **productions** - grammar rules are defined here.
- **code** - user defined code that will be copied into the generated parser file might be placed here.

## Definitions

In the definition section tokens are the only parser elements that are required to be defined. They inform the parser about what tokens may come from the lexer output.

### %token

Lexer tokens are defined in the following way:

```
%token TOKEN_NAME "alias"
```

where `TOKEN_NAME` is the uppercased name of the token, and `"alias"` is the optional alias of the token. The alias is used to refer to the token in the parser productions. If the alias is not specified, the token name shall be used instead.

### %type

Nonterminal types are defined in the following way:

```
%type <Type> nonterminal_name
```

where `<Type>` is the type of the nonterminal and `nonterminal_name` is the lowercased name of the nonterminal. The type of the nonterminal may be any valid Julia type, including user-defined types. By default, if not specified, the type of the nonterminal is set to `Nothing`.

All nonterminal names in the definition file should be lowercase, and all terminal names should be uppercase. This is required to distinguish between terminals and nonterminals in the parser productions.

### %option

Parser options are defined in the following way:

```
%option OPTION_NAME
%option KEYWORD_OPTION_NAME=VALUE
```

where `OPTION_NAME` or `KEYWORD_OPTION_NAME` is the name of the option and `VALUE` is the value of the option. Parser options can be used to change the behaviour of the parser.

Currently these parser options are available:

```
#= Parser type =#
%option SLR
%option LR
%option LALR

#= Tag =#
%option tag=TAG_NAME
%option lexer_tag=LEXER_TAG_NAME
```

First three options are used to specify the type of the parser. By default the parser type is set to `SLR`.

The last two options are used to change the prefix of all generated object names. By default it is set to `__PAR__` for parser files and `__LEX__` for lexer files. To change the prefix of the parser object names, use the `tag` option. If a lexer with a custom prefix is used, the `lexer_tag` option should be used to specify the prefix of the lexer object names.

## Productions

In the productions section grammar rules are defined. The grammar rules are defined in the following way:

```
lhs -> rhs :{ ACTION }:
```

where `lhs` is the name of the nonterminal on the left-hand side of the rule, `rhs` is the sequence of terminals and nonterminals on the right-hand side of the rule, and `ACTION` is the action that will be executed when the rule is reduced. The action is optional.

If a certain nonterminal has more than one production defined, the alternative production should be defined right below the first one, using the `|` symbol:

```
lhs -> rhs     :{ ACTION     }:
     | alt_rhs :{ ALT_ACTION }:
```

### Special production variables

The main task of the parser is to create some sort of structurized representation of the input. To do that, the parser needs to assign variables to the `lhs` nonterminals. Just like in Bison, the variables are assigned using the `$` symbol:

```
lhs -> rhs :{ $$ = $1, ... $n }:
```

where `$n` is the `n`-th element of the `rhs` sequence. The `$$` symbol can also be used to refer to the `lhs` nonterminal in the action. The type assigned to the `$$` should be the same as the type of the `lhs` nonterminal.

### %start

The first `lhs` of the first production is treated as the start symbol of the grammar. To change the start symbol, use the `%start` option:

```
%start START_SYMBOL
```

## Code

In the code section user-defined code that will be copied into the generated parser file might be placed. This section is optional.

### Additional code blocks

Additionally, the user can insert additional code blocks into the definition file using the following delimiters:

```
%{
...
%}
```

Be mindful that the code blocks should not be intermixed with other definition file constructs (e.g. parser options, productions, etc.).

## Comments

Comments in parser definition files are single-line and are enclosed by special delimiters:

```
#= ... =#
```

Comments should not be mixed with other definition file constructs (e.g. parser options, productions, etc.).

## Special function overloading

Some special functions in the generated parser file can be overloaded by the user. The following functions can be overloaded:

- `__PAR__at_end()` - this function is run after the parser has finished parsing the input. By default it returns `false` as an indicator of success.
- `__PAR__main()` - this function is run when the parser is run directly from the command line. By default it either reads the input from the file specified as the first command line argument, tokenizes it using the provided lexer and then proceeds to parse it.
- `__PAR__usage()` - used to print the helper usage message when the parser is run incorrectly from the command line. By default it prints the following message:
  ```
  Usage: $(PROGRAM_FILE) [source file]
  ```

To overload a function, just define it in the code section/block of the parser definition file.

## Valid parser definition files examples

See [Examples](@ref) for valid parser definition files examples.
