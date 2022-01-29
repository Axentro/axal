module Axal::AST
  class FunctionCall < Expression
    getter name : Identifier
    getter args : Array(Expression)

    def initialize(@name, @args = [] of Expression)
    end

    def function_name_as_str
      name.name
    end

    def ==(other : Expression)
      children == other.children
    end

    def children
      [@name, @args]
    end
  end
end
