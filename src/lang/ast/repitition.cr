module Axal::AST
  class Repetition < Expression
    getter condition : String?
    getter block : String?

    def initialize(@condition = nil, @block = nil)
    end

    def ==(other)
      children == other.children
    end

    def children
      [@condition, @block]
    end
  end
end
