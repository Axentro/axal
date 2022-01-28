module Axal::AST
class Return < Expression

    getter expression : String
  
    def initialize(@expression)
    end
  
    def ==(other)
      children == other.children
    end
  
    def children
      [@expression]
    end
  end
  end
  