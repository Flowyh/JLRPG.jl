using Parameters: @consts

abstract type RegexNode end

@consts begin
  doNothing = :DoNothing
end

# Augmented regex end (#)
@kwdef struct End <: RegexNode
  pattern::String
  token::Symbol
  action::Symbol = doNothing
end

struct Character <: RegexNode
  char::Char
end

struct PossibleCharacters <: RegexNode
  chars::Vector{Char}
end

# === Operators ===

struct Concatenation <: RegexNode
  left::RegexNode
  right::RegexNode
end

struct Alternation <: RegexNode
  left::RegexNode
  right::RegexNode
end

struct KleeneStar <: RegexNode
  child::RegexNode
end

struct AtLeastOne <: RegexNode
  child::RegexNode
end

struct Optional <: RegexNode
  child::RegexNode
end

# TODO: Add {} duplication
# TODO: Anchoring (line_start, line_end)
# TODO: Look at Flex: https://westes.github.io/flex/manual/Patterns.html
