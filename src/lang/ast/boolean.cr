module Axal::AST
  class Boolean < Expression
    def initialize(val)
      super(val)
    end

    def ==(other)
      value == other.value
    end

    def children
      [] of Expression
    end
  end
end
