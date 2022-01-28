module Axal::AST
  class FunctionDefinition < Expression
    getter name : Identifier?
    property params : Array(Identifier)
    property body : Block?

    def initialize(@name = nil, @params = [] of Identifier, @body = nil)
    end

    def function_name_as_str
      name.name
    end

    def ==(other : Expression)
      children == other.children
    end

    def children
      [@name, @params, @body]
    end
  end
end
