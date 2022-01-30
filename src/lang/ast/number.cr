module Axal::AST
  class Number < Expression
    def initialize(val : Int32 | Int64 | Float32 | Float64)
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
