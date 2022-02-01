module Axal::AST
    class ExternalCode < Expression
      def initialize(val)
        super(val)
      end
  
      def ==(other : Expression)
        value == other.value
      end
  
      def children
        [] of Expression
      end
    end
  end