module Axal::AST
  class ArrayList < Expression
    property items : Array(Expression)

    def initialize(@items = [] of Expression)
    end

    def ==(other : ArrayList)
      children == other.children
    end

    def children
      [@items]
    end
  end
end
