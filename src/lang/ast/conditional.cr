module Axal::AST
  class Conditional < Expression
    property condition : Expression?
    property when_true : Block?
    property when_false : Block?

    def initialize(@condition = nil, @when_true = nil, @when_false = nil)
    end

    def ==(other : Expression)
      children == other.children
    end

    def children
      [@condition, @when_true, @when_false]
    end
  end
end
