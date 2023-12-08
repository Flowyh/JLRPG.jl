# JLPG.jl

Lexer & LR parser generator for Julia.

## Installation

JLPG.jl can be installed using the Julia package manager. From the Julia REPL, type `]` to enter the Pkg REPL mode and run:

```
pkg> add https://github.com/Flowyh/JLPG.jl
```

## Features

- Generating simplified lexers using [Flex](https://westes.github.io/flex/manual/)-like syntax.
- Generating parsers using [Bison](https://www.gnu.org/software/bison/manual/)-like syntax.
  - Support for **SLR**, **LR(1)** and **LALR(1)** grammars.

The documentation for simplified lexer definition files can be found at [SimpleLexer definition files](@ref) page.

The documentation for parser definition files can be found at [Parser definition files](@ref) page.

Some examples of valid lexer and parser definition files can be found at [Examples](@ref).

## Quick start

### Lexer

The following example shows how to generate a lexer for a simple language that recognizes `+` `*` operators, parenthesis and numbers.

```
WHITESPACE (\s|\n)
NUMBER     0|[1-9]+[0-9]*

%%

{WHITESPACE}+            :{ # Ignore }:
{NUMBER}                 :{
  val::Int = parse(Int, $$)
  return Number(::Int=val)
}:
"*"                      :{ return Multiply() }:
"+"                      :{ return Add()      }:
"("                      :{ return LParen()   }:
")"                      :{ return RParen()   }:

%%
```

To generate the lexer, run the following code:

```julia
using JLPG
generate_lexer("example.jlex")
```

A generated lexer file `__LEX__.jl` will be created in the directory from which the command was run. To test if the lexer works as expected you can run it directly using Julia interpreter:

```bash
$ julia __LEX__.jl
```

the program will wait for any input (until `Ctrl+D` is pressed) and tokenize it.

In this example nothing will be printed to the standard output. You can enable debug mode by running the program with `JULIA_DEBUG=Main` variable enabled, to see what is happening behind the scenes:

```bash
$ JULIA_DEBUG=Main julia __LEX__.jl
```

Alternitavely, you can pass an input file to the lexer:

```bash
$ julia __LEX__.jl example.txt
```

### Parser

The following example shows how to generate a LALR parser for a simple integer arithmetic language.

```
%option LALR

#= Lexer token definitions =#
%token MULTIPLY "*"
%token ADD "+"
%token LPAREN "("
%token RPAREN ")"
%token NUMBER

#= Returned types =#
%type <Int> e
%type <Int> t
%type <Int> f

%%
#= Productions =#
%start s
s -> e         :{ println($1)   }:
e -> e "+" t   :{ $$ = $1 + $3  }:
   | t         :{ $$ = $1       }:
t -> t "*" f   :{ $$ = $1 * $3  }:
   | f         :{ $$ = $1       }:
f -> NUMBER    :{ $$ = $1.value }:
   | "(" e ")" :{ $$ = $2       }:

%%
```

To generate the parser, run the following command:

```julia
using JLPG
generate_parser("example.jpar")
```

A generated parser file `__PAR__.jl` will be created in the directory from which the command was run. To test if the parser works as expected you can run it directly using Julia interpreter, but this time you need to pass an input file to the parser:

```bash
$ julia __PAR__.jl example.txt
```

In this example the parser will tokenize the file, analyze it's syntax and print the result to the standard output. If any syntax error is found, the parser will print an error message and exit.

## License

This project is licensed under the MIT License - see the [LICENSE](https://github.com/Flowyh/JLPG.jl/blob/main/LICENSE) file for details.
