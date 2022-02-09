module Axal::AST
  class DescribeDefinition < Expression
    getter name : Str
    property body : Block?

    def initialize(@name, @body = nil)
    end

    def describe_name_as_str
      @name
    end

    def ==(other : Expression)
      children == other.children
    end

    def children
      [@name, @body]
    end
  end
end
