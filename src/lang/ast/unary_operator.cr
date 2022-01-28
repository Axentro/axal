module Axal::AST
  class UnaryOperator < Expression
    getter operator : TokenKind
    property operand : Expression?

    def initialize(@operator, @operand = nil)
      @operator = operator
      @operand = operand
    end

    def ==(other : UnaryOperator)
      @operator == other.operator && children == other.children
    end

    def children
      [@operand]
    end
  end
end
