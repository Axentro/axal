module Axal::AST
  class Json < Expression
    property items : Hash(String, Expression)

    def initialize(@items = {} of String => Expression)
    end

    def ==(other : Json)
      children == other.children
    end

    def children
      [@items]
    end
  end
end
