using Parameters: @consts

abstract type RegexNode end

@consts begin
  doNothing::Symbol = :DoNothing
end


# === Pos functions stats ===

@kwdef struct NodeStats
  nullable::Bool
  firstpos::Vector{Int}
  lastpos::Vector{Int}
end

# === AST leaves ===

struct Character <: RegexNode
  char::Char
  position::Int
  stats::NodeStats

  function Character(
    char::Char, 
    position::Int
  )::Character
    stats::NodeStats = NodeStats(
      nullable  = nullable(Character),
      firstpos  = firstpos(Character, position),
      lastpos   = lastpos(Character, position)
    )
    return new(char, position, stats)
  end
end

struct PossibleCharacters <: RegexNode
  chars::Vector{Char}
  position::Int
  stats::NodeStats

  function PossibleCharacters(
    chars::Vector{Char}, 
    position::Int
  )::PossibleCharacters
    stats::NodeStats = NodeStats(
      nullable  = nullable(PossibleCharacters),
      firstpos  = firstpos(PossibleCharacters, position),
      lastpos   = lastpos(PossibleCharacters, position)
    )
    return new(chars, position, stats)
  end
end

# Augmented regex end (#)
@kwdef struct End <: RegexNode
  pattern::String
  token::Symbol
  position::Int
  stats::NodeStats
  action::Symbol = doNothing

  function End(
    pattern::String,
    token::Symbol,
    position::Int,
    action::Symbol = doNothing
  )::End
    stats::NodeStats = NodeStats(
      nullable  = nullable(End),
      firstpos  = firstpos(End, position),
      lastpos   = lastpos(End, position)
    )
    return new(pattern, token, position, stats, action)
  end
end

# === Operators ===

struct Concatenation <: RegexNode
  left::RegexNode
  right::RegexNode
  stats::NodeStats

  function Concatenation(
    left::RegexNode,
    right::RegexNode
  )::Concatenation
    stats::NodeStats = NodeStats(
      nullable  = nullable(Concatenation, left, right),
      firstpos  = firstpos(Concatenation, left, right),
      lastpos   = lastpos(Concatenation, left, right)
    )
    return new(left, right, stats)
  end
end

struct Alternation <: RegexNode
  left::RegexNode
  right::RegexNode
  stats::NodeStats

  function Alternation(
    left::RegexNode,
    right::RegexNode
  )::Alternation
    stats::NodeStats = NodeStats(
      nullable  = nullable(Alternation, left, right),
      firstpos  = firstpos(Alternation, left, right),
      lastpos   = lastpos(Alternation, left, right)
    )
    return new(left, right, stats)
  end
end

struct KleeneStar <: RegexNode
  child::RegexNode
  stats::NodeStats

  function KleeneStar(
    child::RegexNode
  )::KleeneStar
    stats::NodeStats = NodeStats(
      nullable  = nullable(KleeneStar),
      firstpos  = firstpos(KleeneStar, child),
      lastpos   = lastpos(KleeneStar, child)
    )
    return new(child, stats)
  end
end

struct AtLeastOne <: RegexNode
  child::RegexNode
  stats::NodeStats

  function AtLeastOne(
    child::RegexNode
  )::AtLeastOne
    stats::NodeStats = NodeStats(
      nullable  = nullable(AtLeastOne, child),
      firstpos  = firstpos(AtLeastOne, child),
      lastpos   = lastpos(AtLeastOne, child)
    )
    return new(child, stats)
  end
end

struct Optional <: RegexNode
  child::RegexNode
  stats::NodeStats

  function Optional(
    child::RegexNode
  )::Optional
    stats::NodeStats = NodeStats(
      nullable  = nullable(Optional),
      firstpos  = firstpos(Optional, child),
      lastpos   = lastpos(Optional, child)
    )
    return new(child, stats)
  end
end

# TODO: Add {} duplication
# TODO: Add anchoring (line_start, line_end)
# TODO: Look at Flex: https://westes.github.io/flex/manual/Patterns.html
# TODO: empty strings?
