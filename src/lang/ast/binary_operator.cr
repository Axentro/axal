require "./expression"
module Axal::AST
  class BinaryOperator < Expression
    getter operator : String
    getter left : String?
    getter right : String?

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
