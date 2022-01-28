module Axal::AST
  class FunctionDefinition < Expression
    getter name : String?
    getter params : Array(Expression)
    getter body : String

    def initialize(@name = nil, @params = [] of Expression, @body = nil)
    end

    def function_name_as_str
      name.name
    end

    def ==(other)
      children == other.children
    end

    def children
      [@name, @params, @body]
    end
  end
end
