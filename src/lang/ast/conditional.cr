module Axal::AST
  class Conditional < Expression
    getter condition : String?
    getter when_true : String?
    getter when_false : String?

    def initialize(@condition = nil, @when_true = nil, @when_false = nil)
    end

    def ==(other)
      children == other.children
    end

    def children
      [@condition, @when_true, @when_false]
    end
  end
end
