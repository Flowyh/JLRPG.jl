using Parameters: @consts

abstract type RegexNode end

@consts begin
  RegexNodeOrNothing = Union{RegexNode, Nothing}
  doNothing::Function = () -> nothing
end

@kwdef struct End <: RegexNode
  parent::RegexNodeOrNothing
  pattern::String
  token::Symbol
  action::Function = doNothing
end

struct Character <: RegexNode
  parent::RegexNodeOrNothing
  char::Char
end

struct CharacterClass <: RegexNode
  parent::RegexNodeOrNothing
  chars::Set{Char}
end

struct Concatenation <: RegexNode
  parent::RegexNodeOrNothing
  left::RegexNode
  right::RegexNode
end

struct Alternation <: RegexNode
  parent::RegexNodeOrNothing
  left::RegexNode
  right::RegexNode
end

struct KleeneStar <: RegexNode
  parent::RegexNodeOrNothing
  child::RegexNode
end

struct AtLeastOne <: RegexNode
  parent::RegexNodeOrNothing
  child::RegexNode
end

struct Optional <: RegexNode
  parent::RegexNodeOrNothing
  child::RegexNode
end
