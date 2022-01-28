module Axal::AST
  class VarBinding < Expression
    getter left : Identifier
    getter right : Expression?

    def initialize(@left, @right)
    end

    def var_name_as_str
      left.name
    end

    def ==(other : Expression)
      children == other.children
    end

    def children
      [@left, @right]
    end
  end
end
