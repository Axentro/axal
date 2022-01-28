module Axal::AST
  class Identifier < Expression
    getter name : String

    EXPECTED_NEXT_TOKENS = [
      TokenKind::NEW_LINE,
      TokenKind::PLUS,
      TokenKind::MINUS,
      TokenKind::ASTERISK,
      TokenKind::FORWARD_SLASH,
      TokenKind::DOUBLE_EQUALS,
      TokenKind::NOT_EQUAL,
      TokenKind::GREATER_THAN,
      TokenKind::LESS_THAN,
      TokenKind::GREATER_THAN_OR_EQUAL,
      TokenKind::LESS_THAN_OR_EQUAL,
      TokenKind::AND,
      TokenKind::OR,
    ]

    def initialize(@name)
    end

    def ==(other)
      name == other.name
    end

    def children
      [] of Expression
    end

    def expects?(next_token)
      EXPECTED_NEXT_TOKENS.includes?(next_token)
    end

  end
end
