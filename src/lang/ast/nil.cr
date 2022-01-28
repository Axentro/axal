module Axal::AST
  class Nil < Expression
    def initialize
      super
    end

    def ==(other)
      self.class == other.class && value == other.value
    end

    def children
      [] of Expression
    end
  end
end
