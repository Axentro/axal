module Axal::AST
  class FunctionCall < Expression
    getter name : Identifier
    getter qualifiers : Array(Identifier)
    getter args : Array(Expression)

    def initialize(@name, @args = [] of Expression, @qualifiers = [] of Identifier)
    end

    def function_name_as_str
      @qualifiers.size > 0 ? @qualifiers.map(&.name).join(".") : @name.name
    end

    def ==(other : Expression)
      children == other.children
    end

    def children
      [@name, @args]
    end
  end
end
