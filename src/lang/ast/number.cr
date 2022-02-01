module Axal::AST
  class Number < Expression
    def initialize(val : Float64)
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
