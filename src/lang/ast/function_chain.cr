module Axal::AST
  class FunctionChain < Expression
    property function_calls : Array(FunctionCall)

    def initialize(@function_calls = [] of FunctionCall)
    end

    def ==(other : FunctionChain)
      children == other.children
    end

    def children
      [@function_calls]
    end
  end
end
