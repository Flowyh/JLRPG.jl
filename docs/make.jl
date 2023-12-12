using Documenter
using JLRPG

makedocs(
  sitename="JLRPG.jl",
  pages = [
    "Getting started" => "index.md",
    "SimpleLexer definition files" => "lexer.md",
    "Parser definition files" => "parser.md",
    "Examples" => "examples.md",
    "Usage" => "usage.md",
    "API" => [
      "SimpleLexer" => "api_simplelexer.md",
      "Parser" => "api_parser.md",
    ]
  ]
)

deploydocs(
  repo = "github.com/Flowyh/JLRPG.jl.git",
)