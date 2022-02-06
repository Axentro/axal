module Axal::AST
    class Json < Expression
      property items : Hash(String, X)
  
      def initialize(@items = {} of String => X)
      end
  
      def ==(other : Json)
        children == other.children
      end
  
      def children
        [@items]
      end
    end
  end
  