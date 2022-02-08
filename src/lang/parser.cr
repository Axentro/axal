module Axal
  class Parser

    getter tokens : Array(Token)

    UNARY_OPERATORS = [TokenKind::EXLAMATION, TokenKind::HYPHEN]
    BINARY_OPERATORS = [
        TokenKind::PLUS, TokenKind::MINUS, TokenKind::ASTERISK, 
        TokenKind::FORWARD_SLASH, TokenKind::DOUBLE_EQUALS, TokenKind::NOT_EQUAL,
        TokenKind::GREATER_THAN, TokenKind::LESS_THAN, TokenKind::GREATER_THAN_OR_EQUAL,
        TokenKind::LESS_THAN_OR_EQUAL
    ]
    LOGICAL_OPERATORS = [TokenKind::OR, TokenKind::AND]

    LOWEST_PRECEDENCE = 0
    PREFIX_PRECEDENCE = 7
    # OPERATOR_PRECEDENCE = {
    #   or:   1,
    #   and:  2,
    #   '==': 3,
    #   '!=': 3,
    #   '>':  4,
    #   '<':  4,
    #   '>=': 4,
    #   '<=': 4,
    #   '+':  5,
    #   '-':  5,
    #   '*':  6,
    #   '/':  6,
    #   '(':  8
    # }

    def initialize(@tokens)
        @ast = AST::Program.new
        @next_p = 0
        @errors = [] of String
    end


  end
end
