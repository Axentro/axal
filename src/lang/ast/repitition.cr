module Axal::AST
  class Repetition < Expression
    property condition : Expression?
    property block : Block?

    def initialize(@condition = nil, @block = nil)
    end

    def ==(other : Expression)
      children == other.children
    end

    def children
      [@condition, @block]
    end
  end
end
