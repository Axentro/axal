module Axal::AST
class FunctionCall < Expression
      
    getter name : String?
    getter args : Array(Expression)

    def initialize(@name = nil, @args = [] of Expression)
    end
  
    def function_name_as_str
      # The instance variable @name is an AST::Identifier.
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
  