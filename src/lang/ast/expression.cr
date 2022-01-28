module Axal::AST
  class Expression
    getter value : Expression? | String? | Float32 | Float64 | Int32 | Int64

    def initialize(@value = nil)
    end

    # TODO Both implementations below are temporary. Expression SHOULD NOT have a concrete implementation of these methods.
    def ==(other)
      self.class == other.class
    end

    def children
      [] of Expression
    end

    # def type
    #   self.class.to_s.split('::').last.underscore # e.g., Stoffle::AST::FunctionCall becomes "function_call"
    # end
  end
end
