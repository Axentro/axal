module Axal::AST
  class Program
    include Shared::ExpressionCollection

    def ==(other : Program)
      children == other.children
    end
  end
end
