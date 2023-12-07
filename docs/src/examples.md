# Examples

## [wc](https://linux.die.net/man/1/wc)-like program

This example shows how to generate a lexer for a simple [wc](https://linux.die.net/man/1/wc)-like program that counts the number of lines and words in a file.

```
%{
no_lines::Int = 0
no_words::Int = 0
%}

INDENT      [ \t]
WHITESPACE  [ \t\n]

%%

{INDENT}+                           :{ }:
\n                                  :{ global no_lines += 1 }:
[a-zA-Z0-9,.;_-]+                   :{ global no_words += 1 }:

%%
#= This is an overload of a special function, which is called =#
#= when the lexer reaches the end of the input.               =#
function __LEX__at_end()
  println("========= OUTPUT =========")
  println("Number of lines: ", no_lines)
  println("Number of words: ", no_words)
  return 0
end
```

To generate the lexer, run the following code:

```julia
using JLPG
generate_lexer("example.jlex")
```

A file named `__LEX__.jl` will be created in the directory from which the command was run.

Let's test the lexer on the following input:

```
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus id dui id ante laoreet tempor. Donec sodales orci sagittis dui porttitor, a pellentesque lectus tristique.

Phasellus scelerisque cursus euismod. Sed ut odio ut libero tristique ullamcorper eget et est. Praesent dignissim eu ex at venenatis.

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aliquam erat volutpat. Nam vel tortor eleifend, posuere quam quis, sollicitudin nisl.
```

Running the generated lexer with the above input will produce the following output:

```
========= OUTPUT =========
Number of lines: 5
Number of words: 65
```

Which is the same as the output of the `wc -wl` program:

```
  5  65 test_input
```

## Generic calculator

Let's create a simple calculator that can evaluate expressions like `(1 + 2) * 3`. The calculator will be able to handle addition, subtraction, multiplication and division. It will also be able to handle parenthesis.

Instead of hardcoding specific return types for the grammar nonterminals, we will define an abstract `Operand` type, which will have all the necessary arithemtic operations defined. To implement this type, the user has to overload basic arithmetic operators from the Julia language (`Base.:+`, `Base.:-`, etc.).

First, let's create a lexer for our calculator:

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

Then, let's define the `Operand` type:

```julia
# Filename: operand.jl
abstract type Operand end

add(a::Operand, b::Operand)::Operand = a + b
sub(a::Operand, b::Operand)::Operand = a - b
mul(a::Operand, b::Operand)::Operand = a * b
div(a::Operand, b::Operand)::Operand = a / b
```

As an example, a simple implementation of the [Galois field](https://en.wikipedia.org/wiki/Finite_field) with parametric order `p` is given below:

```julia
# Filename: galois_field.jl
# Galois field calculator of order P
struct GF{P} <: Operand
  value::Int
  function GF{P}(value::Int) where {P}
    return new(mod(value, P))
  end
end

(Base.:+)(a::GF{P}, b::GF{P}) where P = GF{P}(a.value + b.value)
(Base.:-)(a::GF{P}, b::GF{P}) where P = GF{P}(a.value - b.value)
(Base.:*)(a::GF{P}, b::GF{P}) where P = GF{P}(a.value * b.value)
(Base.:/)(a::GF{P}, b::GF{P}) where P = GF{P}(a.value * invmod(b.value, P))
```

Now, let's define the parser:

```
%option LALR

%{
include("operand.jl") #= Include the operand file =#
include("galois_field.jl") #= Include the Galois field file =#

FIELD_PRIME::Int = 7
%}

#= Lexer token definitions =#
%token MULTIPLY "*"
%token DIVIDE "/"
%token ADD "+"
%token SUBTRACT "-"
%token LPAREN "("
%token RPAREN ")"
%token NUMBER

#= Returned types =#
%type <GF{FIELD_PRIME}> e
%type <GF{FIELD_PRIME}> t
%type <GF{FIELD_PRIME}> f

%%
#= Productions =#
%start s
s -> e         :{ println($1)                    }:
e -> e "+" t   :{ $$ = add($1, $3)               }:
   | e "-" t   :{ $$ = sub($1, $3)               }:
   | t         :{ $$ = $1                        }:
t -> t "*" f   :{ $$ = mul($1, $3)               }:
   | t "/" f   :{ $$ = div($1, $3)               }:
   | f         :{ $$ = $1                        }:
f -> NUMBER    :{ $$ = GF{FIELD_PRIME}($1.value) }:
   | "(" e ")" :{ $$ = $2                        }:

%%
```

This grammar ensures that the order of operations is preserved. Currently there is no way to define the precedence of terminals in the grammar file, so the user has to define the precedence manually in the grammar productions.

To generate the parser, run the following code:

```julia
using JLPG
generate_parser("example.jpar")
```

A file named `__PAR__.jl` will be created in the directory from which the command was run.

Let's test the parser on the following input:

```
(2 + 11) * 6
```

This should equal `1`, since `78 = 1 (mod 7)`.
Running the generated parser with the above input will produce the following output:

```
GaloisField{order=7}(1)
```

## Changing the program arguments of the generated parser

Currently the order of the Galois field calculator is hardcoded in the parser file. To change it, the user has to modify the `FIELD_PRIME` constant in the parser file and regenerate the parser.

To avoid this, the `__PAR__main()` function can be overloaded in the definition file. This function is called when the generated parser is run.

Let's modify the previous example to use below functions:

```julia
function __PAR__usage()
  println("Usage: $(PROGRAM_FILE) [source file] [order]")
end

function __PAR__main()
  if length(ARGS) != 2
    return __PAR__usage()
  elseif ARGS[1] == "-h" || ARGS[1] == "--help"
    return __PAR__usage()
  elseif !isfile(ARGS[1])
    error("File \"$(ARGS[1])\" does not exist")
  else
    try
      global FIELD_PRIME = parse(Int, ARGS[2])
    catch e
      error("Invalid order argument, must be an integer, got: \"$(ARGS[2])\"")
    end

    txt = ""
    open(ARGS[1]) do file
      txt = read(file, String)
      __LEX__bind_cursor(Cursor(txt; source=ARGS[1]))
    end

    tokens = nothing
    try
      tokens = __LEX__tokenize()
    catch e
      e = ErrorException(replace(e.msg, r"\n       " => "\n"))
      @error "Error while tokenizing input" exception=(e, catch_backtrace())
      exit(1)
    end

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

  return __PAR__at_end()
end
```

Now an additional argument has to be provided to the parser, which is the order of the Galois field. Let's test the parser on the following input and order `21`:

```
(2 + 11) * 6
```

This should equal `15`, since `78 = 15 (mod 21)`.

Running the generated parser with the above input and order will produce the following output:

```
GaloisField{order=21}(15)
```

## Simple AST for the calculator

The most powerful feature of each LR parser is the ability to create an abstract syntax tree (AST) for the input. This example shows how to create a simple AST for the calculator from the previous example.

Let's define basic AST node types and a function that will evaluate the provided arithmetic operations tree:

```julia
# Filename: ast.jl
abstract type Node end

struct NumNode <: Node
  value::Operand
end

struct AddNode <: Node
  left::Node
  right::Node
end

struct SubNode <: Node
  left::Node
  right::Node
end

struct MulNode <: Node
  left::Node
  right::Node
end

struct DivNode <: Node
  left::Node
  right::Node
end

eval(n::Num)::Operand = n.value
eval(n::Add)::Operand = add(eval(n.left), eval(n.right))
eval(n::Sub)::Operand = sub(eval(n.left), eval(n.right))
eval(n::Mul)::Operand = mul(eval(n.left), eval(n.right))
eval(n::Div)::Operand = div(eval(n.left), eval(n.right))
```

The abstract `Node` type will be used as a return type for the grammar nonterminals. All operators contain references to other `Node` objects, which allows us to create a tree structure.

Now, let's modify the parser from the previous example to return `Node` objects:

```
%option LALR

%{
include("operand.jl") #= Include the operand file =#
include("galois_field.jl") #= Include the Galois field file =#
include("ast.jl") #= Include the AST file =#

FIELD_PRIME::Int = 7
%}

#= Lexer token definitions =#
%token MULTIPLY "*"
%token DIVIDE "/"
%token ADD "+"
%token SUBTRACT "-"
%token LPAREN "("
%token RPAREN ")"
%token NUMBER

#= Returned types =#
%type <Node> e
%type <Node> t
%type <Node> f

%%
#= Productions =#
%start s
s -> e         :{ println($1); println(eval($1))          }:
e -> e "+" t   :{ $$ = AddNode($1, $3)                    }:
   | e "-" t   :{ $$ = SubNode($1, $3)                    }:
   | t         :{ $$ = $1                                 }:
t -> t "*" f   :{ $$ = MulNode($1, $3)                    }:
   | t "/" f   :{ $$ = DivNode($1, $3)                    }:
   | f         :{ $$ = $1                                 }:
f -> NUMBER    :{ $$ = NumNode(GF{FIELD_PRIME}($1.value)) }:
   | "(" e ")" :{ $$ = $2                                 }:

%%
```

As you can see, the `GF{P}` type will still be used, but now a tree-like structure will be created from the input. To see what tree has been created for the given input, an additional print statement has been added to the `s` production.

To generate the parser, run the following code:

```julia
using JLPG
generate_parser("example.jpar")
```

For the same input as in the previous example, the following output will be produced:

```
MulExpr(AddExpr(Num(GaloisField{order=7}(2)), Num(GaloisField{order=7}(4))), Num(GaloisField{order=7}(6)))
GaloisField{order=7}(1)
```

This is a proper way of creating an AST for this example, since the order of operations and parenthesis are preserved.
