using Documenter
using JLPG

makedocs(
  sitename="JLPG.jl",
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
  # modules=[JLPG]
)

deploydocs(
  repo = "github.com/Flowyh/JLPG.jl.git",
)