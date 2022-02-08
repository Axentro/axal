module Axal
    module AST
      module Shared
        module ExpressionCollection
      
          def initialize
            @expressions = [] of Array(Token)
          end

          def expressions
            @expressions
          end
  
          def <<(expr)
            @expressions << expr
          end
  
          def ==(other)
            @expressions == other.expressions
          end
  
          def children
            expressions
          end
        end
      end
    end
  end
  