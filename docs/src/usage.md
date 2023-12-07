# Usage

## Generating a lexer

After the lexer definition file is created, it can be used to generate a lexer. To do so, run the following program:

```julia
using JLPG
generate_lexer("path/to/lexer.jlex", "path/to/generated/lexer.jl")
```

This will generate a lexer file in the specified location. The generated lexer file will contain all the variables needed to tokenize the input string. Running the lexer directly without an input file path will open an stdin prompt, which has to be terminated with `Ctrl+D` combination. To run the lexer on a file, pass the file path as the first command line argument.

To see the actions performed by the lexer, run it with the `JULIA_DEBUG=Main` environment variable set:

```
JULIA_DEBUG=Main julia path/to/generated/lexer.jl [source file]
```

## Generating a parser

To generate a parser, run the following program:

```julia
using JLPG
generate_parser("path/to/parser.jpar", "path/to/generated/parser.jl")
```

This will generate a parser file in the specified location. The generated parser file will contain all the variables needed to parse the input string. To run the parser on a file, pass the file path as the first command line argument.

Generated parsers require a path to the lexer file to be specified in the parses definition file. By default the generated parser program checks, whether a `__LEX__.jl` file is present in the same directory as the parser file. If it is not, a warning message is printed. To specify a custom lexer file path, include it inside of a code section/block in the parser definition file:

```
%{
include("path/to/lexer.jl")
%}
```

To see the actions performed by the parser, run it with the `JULIA_DEBUG=Main` environment variable set:

```
JULIA_DEBUG=Main julia path/to/generated/parser.jl [source file]
```
