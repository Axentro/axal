require "./expression"

module Axal::AST
  class BinaryOperator < Expression
    getter operator : TokenKind
    getter left : Expression?
    property right : Expression?

    def initialize(@operator, @left = nil, @right = nil)
    end

    def ==(other : BinaryOperator)
      operator == other.operator && children == other.children
    end

    def children
      [left, right]
    end
  end
end
