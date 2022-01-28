module Axal::AST
  module Shared::ExpressionCollection
    def initialize
      @expressions = [] of Expression
    end

    def expressions
      @expressions
    end

    def <<(expr : Expression)
      @expressions << expr
    end

    def ==(other : Expression)
      @expressions == other.children
    end

    def children
      @expressions
    end
  end
end
