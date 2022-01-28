module Axal::AST
  class UnaryOperator < Expression
    getter operator : String
    getter operand : String?

    def initialize(@operator, @operand = nil)
      @operator = operator
      @operand = operand
    end

    def ==(other)
      @operator == other.operator && @children == other.children
    end

    def children
      [@operand]
    end
  end
end
