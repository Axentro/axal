module Axal::AST
  class Block
    include Shared::ExpressionCollection

    def ==(other : Block)
      children == other.children
    end
  end
end
