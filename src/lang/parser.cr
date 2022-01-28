module Axal
  class Parser
    getter tokens : Array(Token)
    getter next_p : Int32
    getter ast : AST::Program
    getter errors : Array(Exception) = [] of Exception

    UNARY_OPERATORS  = [TokenKind::EXCLAMATION, TokenKind::HYPHEN]
    BINARY_OPERATORS = [
      TokenKind::PLUS, TokenKind::HYPHEN, TokenKind::ASTERISK,
      TokenKind::FORWARD_SLASH, TokenKind::DOUBLE_EQUALS, TokenKind::NOT_EQUAL,
      TokenKind::GREATER_THAN, TokenKind::LESS_THAN, TokenKind::GREATER_THAN_OR_EQUAL,
      TokenKind::LESS_THAN_OR_EQUAL,
    ]
    LOGICAL_OPERATORS = [TokenKind::OR, TokenKind::AND]

    LOWEST_PRECEDENCE = 0
    PREFIX_PRECEDENCE = 7

    OPERATOR_PRECEDENCE = {
      TokenKind::OR                    => 1,
      TokenKind::AND                   => 2,
      TokenKind::DOUBLE_EQUALS         => 3,
      TokenKind::NOT_EQUAL             => 3,
      TokenKind::GREATER_THAN          => 4,
      TokenKind::LESS_THAN             => 4,
      TokenKind::GREATER_THAN_OR_EQUAL => 4,
      TokenKind::LESS_THAN_OR_EQUAL    => 4,
      TokenKind::PLUS                  => 5,
      TokenKind::HYPHEN                => 5,
      TokenKind::ASTERISK              => 6,
      TokenKind::FORWARD_SLASH         => 6,
      TokenKind::LEFT_PAREN            => 8,
    }

    def initialize(@tokens)
      @ast = AST::Program.new
      @next_p = 0
    end

    def parse
      while pending_tokens?
        consume

        node = parse_expr_recursively
        @ast << node.not_nil! if node != nil
      end

      @ast
    end

    def build_token(kind : TokenKind, lexeme, location)
      Token.new(kind, lexeme, nil, location)
    end

    def pending_tokens?
      @next_p < @tokens.size
    end

    def nxt_not_terminator?
      nxt.kind != TokenKind::NEW_LINE && nxt.kind != TokenKind::EOF
    end

    def consume(offset = 1)
      t = lookahead(offset)
      @next_p += offset
      t
    end

    def consume_if_nxt_is(expected_kind)
      if nxt.kind == expected_kind
        consume
        true
      else
        unexpected_token_error(expected_kind)
        false
      end
    end

    def previous
      lookahead(-1)
    end

    def current
      lookahead(0)
    end

    def nxt
      lookahead
    end

    def lookahead(offset = 1)
      lookahead_p = (@next_p - 1) + offset
      # return nil if lookahead_p < 0 || lookahead_p >= @tokens.size
      raise "lookahead error" if lookahead_p < 0 || lookahead_p >= @tokens.size

      tokens[lookahead_p]
    end

    def current_precedence
      OPERATOR_PRECEDENCE[current.kind] || LOWEST_PRECEDENCE
    end

    def nxt_precedence
      OPERATOR_PRECEDENCE[nxt.kind] || LOWEST_PRECEDENCE
    end

    def unrecognized_token_error
      errors << Error::Syntax::UnrecognizedToken.new(current)
    end

    def unexpected_token_error(expected_kind = nil)
      errors << Error::Syntax::UnexpectedToken.new(current, nxt, expected_kind)
    end

    def check_syntax_compliance(ast_node)
      return if ast_node.expects?(nxt)
      unexpected_token_error
    end

    def determine_infix_function(token = current)
      if (BINARY_OPERATORS + LOGICAL_OPERATORS).includes?(token.kind)
        :parse_binary_operator
      elsif token.kind == TokenKind::LEFT_PAREN
        :parse_function_call
      end
    end

    def parse_identifier
      if lookahead.kind == TokenKind::EQUALS
        parse_var_binding
      else
        ident = AST::Identifier.new(current.lexeme)
        check_syntax_compliance(ident)
        ident
      end
    end

    def parse_string
      AST::Str.new(current.literal)
    end

    def parse_number
      AST::Number.new(current.literal)
    end

    def parse_boolean
      AST::Boolean.new(current.lexeme == "true")
    end

    def parse_nil
      AST::Nil.new
    end

    def parse_function_definition
      return unless consume_if_nxt_is(TokenKind::IDENTIFIER)
      fn = AST::FunctionDefinition.new(AST::Identifier.new(current.lexeme))

      if nxt.kind != TokenKind::NEW_LINE && nxt.kind != TokenKind::COLON
        unexpected_token_error
        return
      end

      if nxt.kind == TokenKind::COLON
        if params = parse_function_params
          fn.params = params
        end
      end

      return unless consume_if_nxt_is(TokenKind::NEW_LINE)
      fn.body = parse_block

      fn
    end

    def parse_function_params
      consume
      return unless consume_if_nxt_is(TokenKind::IDENTIFIER)

      identifiers = [] of AST::Identifier
      identifiers << AST::Identifier.new(current.lexeme)

      while nxt.kind == TokenKind::COMMA
        consume
        return unless consume_if_nxt_is(TokenKind::IDENTIFIER)
        identifiers << AST::Identifier.new(current.lexeme)
      end

      identifiers
    end

    def parse_function_call(identifier)
      AST::FunctionCall.new(identifier, parse_function_call_args)
    end

    def parse_function_call_args
      args = [] of String

      # Function call without arguments.
      if nxt.kind == TokenKind::RIGHT_PAREN
        consume
        return args
      end

      consume
      args << parse_expr_recursively

      while nxt.kind == TokenKind::COMMA
        consume(2)
        args << parse_expr_recursively
      end

      return unless consume_if_nxt_is(TokenKind::RIGHT_PAREN)
      args
    end

    def parse_conditional
      conditional = AST::Conditional.new
      consume
      conditional.condition = parse_expr_recursively
      return unless consume_if_nxt_is(TokenKind::NEW_LINE)

      conditional.when_true = parse_block

      # TODO: Probably is best to use nxt and check directly; ELSE is optional and should not result in errors being added to the parsing. Besides that: think of some sanity checks (e.g., no parser errors) that maybe should be done in EVERY parser test.
      if consume_if_nxt_is(TokenKind::ELSE)
        return unless consume_if_nxt_is(TokenKind::NEW_LINE)
        conditional.when_false = parse_block
      end

      conditional
    end

    def parse_repetition
      repetition = AST::Repetition.new
      consume
      repetition.condition = parse_expr_recursively
      return unless consume_if_nxt_is(TokenKind::NEW_LINE)

      repetition.block = parse_block
      repetition
    end

    def parse_block
      consume
      block = AST::Block.new
      while current.kind != TokenKind::END && current.kind != TokenKind::EOF && nxt.kind != TokenKind::ELSE
        expr = parse_expr_recursively
        block << expr unless expr.nil?
        consume
      end
      unexpected_token_error(current.kind) if current.kind == TokenKind::EOF

      block
    end

    def parse_grouped_expr
      consume

      expr = parse_expr_recursively
      return unless consume_if_nxt_is(TokenKind::RIGHT_PAREN)

      expr
    end

    # TODO Temporary impl; reflect more deeply about the appropriate way of parsing a terminator.
    def parse_terminator
      nil
    end

    def parse_var_binding
      identifier = AST::Identifier.new(current.lexeme)
      consume(2)

      AST::VarBinding.new(identifier, parse_expr_recursively)
    end

    def parse_return
      consume
      AST::Return.new(parse_expr_recursively)
    end

    def parse_unary_operator
      op = AST::UnaryOperator.new(current.kind)
      consume
      op.operand = parse_expr_recursively(PREFIX_PRECEDENCE)

      op
    end

    def parse_binary_operator(left)
      op = AST::BinaryOperator.new(current.kind, left)
      op_precedence = current_precedence

      consume
      op.right = parse_expr_recursively(op_precedence)

      op
    end

    # TODO - fix this
    def send(a, b)
      puts "SEND: #{a}, #{b}"
    end

    def determine_parsing_function2
      if [TokenKind::RETURN, TokenKind::IDENTIFIER, TokenKind::NUMBER, TokenKind::STRING, TokenKind::TRUE,
          TokenKind::FALSE, TokenKind::NIL, TokenKind::FN, TokenKind::IF, TokenKind::WHILE].includes?(current.kind)
        "parse_#{current.kind}"
      elsif current.kind == TokenKind::LEFT_PAREN
        parse_grouped_expr
      elsif [TokenKind::NEW_LINE, TokenKind::EOF].includes?(current.kind)
        parse_terminator
      elsif UNARY_OPERATORS.includes?(current.kind)
        parse_unary_operator
      end
    end

    def parse_expr_recursively(precedence = LOWEST_PRECEDENCE)
      expr = case current.kind
             when TokenKind::RETURN
               parse_return
             when TokenKind::IDENTIFIER
              parse_identifier
             when TokenKind::NUMBER
               parse_number
             when TokenKind::STRING
               parse_string
             when TokenKind::TRUE, TokenKind::FALSE
               parse_boolean
             when TokenKind::NIL
               parse_nil
             when TokenKind::FN
               parse_function_definition
             when TokenKind::IF
               parse_conditional
             when TokenKind::WHILE
               parse_repetition
             when TokenKind::LEFT_PAREN
               parse_grouped_expr
             when TokenKind::NEW_LINE, TokenKind::EOF
               parse_terminator
             else
               if UNARY_OPERATORS.includes?(current.kind)
                 parse_unary_operator
               else
                 unrecognized_token_error
                 return
               end
             end
      return if expr.nil? # When expr is nil, it means we have reached a \n or a eof.

                # Note that here we are checking the NEXT token.
      while nxt_not_terminator? && precedence < nxt_precedence
        infix_parsing_function = determine_infix_function(nxt)

        return expr if infix_parsing_function.nil?

        consume
        expr = send(infix_parsing_function, expr)
      end

      expr
    end

    def parse_expr_recursively2(precedence = LOWEST_PRECEDENCE)
      parsing_function = determine_parsing_function
      if parsing_function.nil?
        unrecognized_token_error
        return
      end
      expr = send(parsing_function)
      return if expr.nil? # When expr is nil, it means we have reached a \n or a eof.

                # Note that here we are checking the NEXT token.
      while nxt_not_terminator? && precedence < nxt_precedence
        infix_parsing_function = determine_infix_function(nxt)

        return expr if infix_parsing_function.nil?

        consume
        expr = send(infix_parsing_function, expr)
      end

      expr
    end
  end
end
