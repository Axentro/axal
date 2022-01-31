module Axal::AST
  class ModuleDefinition < Expression
    getter name : Identifier
    property body : Block?

    def initialize(@name, @body = nil)
    end

    def module_name_as_str
      name.name
    end

    def ==(other : Expression)
      children == other.children
    end

    def children
      [@name, @body]
    end
  end
end
