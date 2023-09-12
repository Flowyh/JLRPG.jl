using Parameters: @consts

@enum Assoc left right
@enum Operator star plus question_mark alternation concatenation line_start line_end group_start group_end

struct OperatorPrecedenceEntry
  prec::Int
  assoc::Assoc
end

@consts begin
  # See: https://pubs.opengroup.org/onlinepubs/9699919799/basedefs/V1_chap09.html#tag_09_04_08
  OperatorsPrecedenceTable::Dict{Operator, OperatorPrecedenceEntry} = Dict(
    # Escaped characters (6) (unary) handled by espaced char token
    # Brackets (5) handled by character class token
    # Grouping
    group_start => OperatorPrecedenceEntry(4, right),
    group_end => OperatorPrecedenceEntry(4, left),
    # Duplication (*, +, ?, {})
    star => OperatorPrecedenceEntry(3, left),
    plus => OperatorPrecedenceEntry(3, left),
    question_mark => OperatorPrecedenceEntry(3, left),
    # TODO: Add {} duplication
    # Concatenation
    concatenation => OperatorPrecedenceEntry(2, left),
    # Anchoring
    line_start => OperatorPrecedenceEntry(1, right),
    line_end => OperatorPrecedenceEntry(1, left),
    # Alternation
    alternation => OperatorPrecedenceEntry(0, left)
  )

  StringToOperator::Dict{String, Operator} = Dict(
    "*" => star,
    "+" => plus,
    "?" => question_mark,
    "|" => alternation,
    "^" => line_start,
    raw"$" => line_end,
    "" => concatenation,
    "(" => group_start,
    ")" => group_end
  )

  # TODO: Load charset config from file
  Charsets::Dict{Symbol, String} = Dict(
    :ASCII => join([Char(i) for i in 0:127], ""),
    # TODO: Add Unicode, UTF-8 support
  )

  CharsetToAllPossibleCharacters::Dict{Symbol, PossibleCharacters} = Dict(
    :ASCII => PossibleCharacters([Char(i) for i in 0:127])
    # TODO: Add Unicode, UTF-8 support
  )
end

function regexOperatorToASTNode!(
  op::Operator, 
  output_stack::Vector{RegexNode}
)::RegexNode
  if op == star
    return KleeneStar(pop!(output_stack))
  elseif op == plus
    return AtLeastOne(pop!(output_stack))
  elseif op == question_mark
    return Optional(pop!(output_stack))
  elseif op == alternation
    right, left = (pop!(output_stack), pop!(output_stack))
    return Alternation(left, right)
  elseif op == concatenation
    right, left = (pop!(output_stack), pop!(output_stack))
    return Concatenation(left, right)
  else
    error("Unknown regex operator")
  end

  # elseif op == line_start
    # return ???(nothing)
  # elseif op == line_end
    # return ???(nothing)
end

function characterClassToSet(
  pattern::String,
  charset::Symbol
)::Vector{Char}
  re = Regex(pattern)
  return [Char(only(m.match)) for m in eachmatch(re, Charsets[charset]) |> collect]
end

function treeify(
  regex::String, 
  token::Symbol;
  action::Symbol = doNothing,
  charset::Symbol = :ASCII
)::Union{RegexNode, Nothing}
  return _treeify_regex(tokenize(regex), regex, token, action, charset)
end

# A modified version of Dijkstra's shunting yard algorithm
# which produces an abstract syntax tree (AST) of the regex.
# See: https://en.wikipedia.org/wiki/Shunting_yard_algorithm
function _treeify_regex(
  regex_tokens::Vector{Tuple{Token, String}},
  pattern::String,
  lexing_token::Symbol,
  action::Symbol,
  charset::Symbol
)::Union{RegexNode, Nothing}
  if isempty(regex_tokens)
    error("Empty regex")
  end

  operator_stack::Vector{Operator} = []
  output_stack::Vector{RegexNode} = []

  while !isempty(regex_tokens)
    (token, lexem) = popfirst!(regex_tokens)
    if token == character
      push!(output_stack, Character(only(lexem[1])))
    elseif token == escaped_character
      push!(output_stack, Character(only(lexem[2])))
    elseif token == any_character
      push!(output_stack, CharsetToAllPossibleCharacters[charset])
    elseif token == character_class
      push!(output_stack, PossibleCharacters(characterClassToSet(lexem, charset)))
    elseif token == operator
      if !isempty(operator_stack)
        op_1 = StringToOperator[lexem]
        (; prec, assoc) = OperatorsPrecedenceTable[op_1]
        (prec_1, assoc_1) = (prec, assoc)

        op_2 = operator_stack[end]
        (; prec, assoc) = OperatorsPrecedenceTable[op_2]
        prec_2 = prec

        while op_2 != group_start && 
              (prec_2 > prec_1 || (prec_2 == prec_1 && assoc_1 == left))
          op_node = regexOperatorToASTNode!(op_2, output_stack)
          push!(output_stack, op_node)
          pop!(operator_stack)

          if isempty(operator_stack)
            break
          end

          op_2 = operator_stack[end]
        end
      end
      push!(operator_stack, StringToOperator[lexem])
    elseif token == left_paren
      push!(operator_stack, group_start)
    elseif token == right_paren
      if length(operator_stack) == 0
        error("Mismatched parentheses")
      end
      op = operator_stack[end]

      while op != group_start
        if length(operator_stack) == 0
          error("Mismatched parentheses")
        end

        op_node = regexOperatorToASTNode!(op, output_stack)
        push!(output_stack, op_node)
        pop!(operator_stack)

        if isempty(operator_stack)
          break
        end

        op = operator_stack[end]
      end

      if operator_stack[end] != group_start
        error("Mismatched parentheses")
      end

      pop!(operator_stack)
    else
      error("Unknown token")
    end
  end

  while !isempty(operator_stack)
    op = operator_stack[end]

    if op == group_start
      error("Mismatched parentheses")
    end

    op_node = regexOperatorToASTNode!(op, output_stack)
    push!(output_stack, op_node)
    pop!(operator_stack)
  end

  if length(output_stack) != 1
    error("Invalid regex")
    return
  end

  return Concatenation(output_stack[1], End(pattern, lexing_token, action))
end
