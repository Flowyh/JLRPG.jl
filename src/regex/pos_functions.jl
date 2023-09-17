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

# Compute followpos for each node and return a dictionary mapping node => followpos
# Traverse using postorder DFS and compute it bottom-up
function followpos(
  node::RegexNode
)::Dict{Int, Vector{Int}}
  followpos_dict = Dict{Int, Vector{Int}}()
  _followpos_dfs!(node, followpos_dict)
  return followpos_dict
end

function _followpos_dfs!(
  node::RegexNode, 
  followpos_dict::Dict{Int, Vector{Int}}
)
  if node isa Concatenation
    _followpos_dfs!(node.left, followpos_dict)
    _followpos_dfs!(node.right, followpos_dict)
    lastpos_left = lastpos(node.left)
    firstpos_right = firstpos(node.right)
    for pos in lastpos_left
      if pos in keys(followpos_dict)
        followpos_dict[pos] = union(
          followpos_dict[pos], firstpos_right
        )
      else
        followpos_dict[pos] = firstpos_right
      end
    end
  elseif node isa KleeneStar || node isa AtLeastOne || node isa Optional
    lastpos_child = lastpos(node.child)
    firstpos_child = firstpos(node.child)
    for pos in lastpos_child
      if pos in keys(followpos_dict)
        followpos_dict[pos] = union(
          followpos_dict[pos], firstpos_child
        )
      else
        followpos_dict[pos] = firstpos_child
      end
    end
  elseif node isa Alternation
    _followpos_dfs!(node.left, followpos_dict)
    _followpos_dfs!(node.right, followpos_dict)
  else # Character, PossibleCharacters, End - tree leaf nodes
    return
  end
end