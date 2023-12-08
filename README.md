# JLPG.jl

LR parser & lexer generator for Julia.

[![Build Status](https://github.com/Flowyh/JLPG.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/Flowyh/JLPG.jl/actions/workflows/CI.yml?query=branch%3Amain)

This package provides a parser and lexer generator for Julia inspired by [GNU Bison](https://www.gnu.org/software/bison/manual/) and [Flex](https://westes.github.io/flex/manual/) respectively. The generated parsers and lexers are written in pure Julia and do not require any external dependencies (aside from the `JLPG.jl` library). To generate a parser or lexer, a definition file has to be written in a bison/flex-like syntax.

The library currently features:

- SLR, LR(1) and LALR(1) parser generation
- Generation of simplified lexers (which use PCRE2 regex matching loops instead of a DFA)

## Installation

The package can be installed with the Julia package manager. From the Julia REPL, type `]` to enter the Pkg REPL mode and run:

```
pkg> add https://github.com/Flowyh/JLPG.jl
```
Currently the package is not registered in the Julia package registry.

## Usage

The package provides two functions `generate_lexer` and `generate_parser` which can be used to generate a lexer or parser respectively. Both functions take a definition file as input and return a Julia source file containing the generated lexer/parser. The generated lexer/parser can then be included in other Julia source files or modules.

### Lexer definition files

The following example shows how to define a lexer for a simple calculator language:

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
"/"                      :{ return Divide()   }:
"+"                      :{ return Add()      }:
"-"                      :{ return Subtract() }:
"("                      :{ return LParen()   }:
")"                      :{ return RParen()   }:

%%
```

The following example shows how to define a simple grammar for the calculator:

```
%option LALR

#= Lexer token definitions =#
%token MULTIPLY "*"
%token DIVIDE "/"
%token ADD "+"
%token SUBTRACT "-"
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
   | e "-" t   :{ $$ = $1 - $3  }:
   | t         :{ $$ = $1       }:
t -> t "*" f   :{ $$ = $1 * $3  }:
   | t "/" f   :{ $$ = $1 / $3  }:
   | f         :{ $$ = $1       }:
f -> NUMBER    :{ $$ = $1.value }:
   | "(" e ")" :{ $$ = $2       }:

%%
```

Generate both lexer and parser:

```julia
using JLPG
generate_lexer("example.jlex")
generate_parser("example.jpar")
```

Files `__LEX__.jl` and `__PAR__.jl` will be generated in the directory, from which the functions were called.

Run the generated parser for the following input file:

```bash
$ cat input.txt
2 + 2 * 2
$ julia __PAR__.jl input.txt
6
```

For more examples see the `examples` directory.
Documentation is available at []().
