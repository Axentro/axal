module Axal
  module Runtime
    class StackFrame
      getter fn_def : AST::Expression
      getter fn_call : AST::Expression
      getter env : Hash(String, (AST::Expression | X))

      def initialize(@fn_def, @fn_call)
        @env = {} of String => String | AST::Expression | X
      end
    end
  end
end
