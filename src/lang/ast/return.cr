module Axal::AST
  class Return < Expression
    getter expression : Expression?

    def initialize(@expression)
    end

    def ==(other : Expression)
      children == other.children
    end

    def children
      [@expression]
    end
  end
end
