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

# ========== Pos functions ==========

using Base: ImmutableDict

# === Nullable ===

function nullable(node::RegexNode)::Bool
  return node.stats.nullable
end

function nullable(::Type{Character})::Bool
  return false
end

function nullable(::Type{PossibleCharacters})::Bool
  return false
end

function nullable(::Type{End})::Bool
  return false
end

function nullable(::Type{Concatenation}, left::RegexNode, right::RegexNode)::Bool
  return nullable(left) && nullable(right)
end

function nullable(::Type{Alternation}, left::RegexNode, right::RegexNode)::Bool
  return nullable(left) || nullable(right)
end

function nullable(::Type{KleeneStar})::Bool
  return true
end

function nullable(::Type{AtLeastOne}, child::RegexNode)::Bool
  return nullable(child)
end

function nullable(::Type{Optional})::Bool
  return true
end

# === Firstpos ===

function firstpos(node::RegexNode)::Vector{Int}
  return node.stats.firstpos
end

function firstpos(::Type{Character}, position::Int)::Vector{Int}
  return [position]
end

function firstpos(::Type{PossibleCharacters}, position::Int)::Vector{Int}
  return [position]
end

function firstpos(::Type{End}, position::Int)::Vector{Int}
  return [position]
end

function firstpos(::Type{Concatenation}, left::RegexNode, right::RegexNode)::Vector{Int}
  if nullable(left)
    return union(firstpos(left), firstpos(right))
  else
    return firstpos(left)
  end
end

function firstpos(::Type{Alternation}, left::RegexNode, right::RegexNode)::Vector{Int}
  return union(firstpos(left), firstpos(right))
end

function firstpos(::Type{KleeneStar}, child::RegexNode)::Vector{Int}
  return firstpos(child)
end

function firstpos(::Type{AtLeastOne}, child::RegexNode)::Vector{Int}
  return firstpos(child)
end

function firstpos(::Type{Optional}, child::RegexNode)::Vector{Int}
  return firstpos(child)
end

# === Lastpos ===

function lastpos(node::RegexNode)::Vector{Int}
  return node.stats.lastpos
end

function lastpos(::Type{Character}, position::Int)::Vector{Int}
  return [position]
end

function lastpos(::Type{PossibleCharacters}, position::Int)::Vector{Int}
  return [position]
end

function lastpos(::Type{End}, position::Int)::Vector{Int}
  return [position]
end

function lastpos(::Type{Concatenation}, left::RegexNode, right::RegexNode)::Vector{Int}
  if nullable(right)
    return union(lastpos(left), lastpos(right))
  else
    return lastpos(right)
  end
end

function lastpos(::Type{Alternation}, left::RegexNode, right::RegexNode)::Vector{Int}
  return union(lastpos(left), lastpos(right))
end

function lastpos(::Type{KleeneStar}, child::RegexNode)::Vector{Int}
  return lastpos(child)
end

function lastpos(::Type{AtLeastOne}, child::RegexNode)::Vector{Int}
  return lastpos(child)
end

function lastpos(::Type{Optional}, child::RegexNode)::Vector{Int}
  return lastpos(child)
end

# === Followpos ===

# TODO: compute for whole tree

function followpos(
  ::Union{Type{Character}, Type{PossibleCharacters}, Type{End}}
)::ImmutableDict{Int, Vector{Int}}
  return ImmutableDict()
end

function followpos(
  ::Type{Alternation}
)::ImmutableDict{Int, Vector{Int}}
  return ImmutableDict()
end

function followpos(
  ::Type{Concatenation},
  left::RegexNode,
  right::RegexNode
)::ImmutableDict{Int, Vector{Int}}
  lastpos_left = lastpos(left)
  firstpos_right = firstpos(right)
  result::ImmutableDict{Int, Vector{Int}} = ImmutableDict()
  for i in lastpos_left
    result[i] = firstpos_right
  end
  return result
end

function followpos(
  ::Union{Type{KleeneStar}, Type{AtLeastOne}, Type{Optional}},
  child::RegexNode
)::ImmutableDict{Int, Vector{Int}}
  lastpos_child = lastpos(child)
  firstpos_child = firstpos(child)
  result::ImmutableDict{Int, Vector{Int}} = ImmutableDict()
  for i in lastpos_child
    result[i] = firstpos_child
  end
  return result
end

# TODO: Add {} duplication
# TODO: Add anchoring (line_start, line_end)
# TODO: Look at Flex: https://westes.github.io/flex/manual/Patterns.html
# TODO: empty strings?
