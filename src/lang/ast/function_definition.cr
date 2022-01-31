module Axal::AST
  class FunctionDefinition < Expression
    getter name : Identifier
    property params : Array(Identifier)
    property body : Block?
    property module_name : Identifier?

    def initialize(@name, @params = [] of Identifier, @body = nil)
    end

    def function_name_as_str
      @module_name.nil? ? @name.name : "#{@module_name.not_nil!.name}.#{@name.name}"
    end

    def ==(other : Expression)
      children == other.children
    end

    def children
      [@name, @params, @body]
    end
  end
end
