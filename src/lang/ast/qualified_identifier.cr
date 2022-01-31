module Axal::AST
  class QualifiedIdentifier < Expression
    getter qualifiers : Array(Identifier)

    def initialize(@qualifiers)
    end

    def ==(other : QualifiedIdentifier)
      qualifiers == other.qualifiers
    end

    def children
      [] of Expression
    end
  end
end
