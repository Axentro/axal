module Axal
  class Parser
    getter tokens : Array(Token)
    getter next_p : Int32
    getter ast : AST::Program
    getter errors : Array(Exception) = [] of Exception
    getter chain : AST::FunctionChain? = nil

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
      @function_calls = [] of AST::FunctionCall
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
      return build_token(TokenKind::EOF, "", current.location) if lookahead_p < 0 || lookahead_p >= @tokens.size

      tokens[lookahead_p]
    end

    def current_precedence
      OPERATOR_PRECEDENCE[current.kind]? || LOWEST_PRECEDENCE
    end

    def nxt_precedence
      OPERATOR_PRECEDENCE[nxt.kind]? || LOWEST_PRECEDENCE
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

    def parse_identifier
      if lookahead.kind == TokenKind::EQUALS
        parse_var_binding
      elsif lookahead.kind == TokenKind::DOT
        parse_qualified_identifier
      else
        ident = AST::Identifier.new(current.lexeme)
        check_syntax_compliance(ident)
        ident
      end
    end

    def parse_qualified_identifier
      identifiers = [] of AST::Identifier
      identifiers << AST::Identifier.new(current.lexeme)
      consume
      return unless consume_if_nxt_is(TokenKind::IDENTIFIER)

      identifiers << AST::Identifier.new(current.lexeme)

      while nxt.kind == TokenKind::DOT
        consume
        return unless consume_if_nxt_is(TokenKind::IDENTIFIER)
        identifiers << AST::Identifier.new(current.lexeme)
      end
      AST::QualifiedIdentifier.new(identifiers)
    end

    def parse_string
      AST::Str.new(current.literal)
    end

    def parse_external_code
      AST::ExternalCode.new(current.literal)
    end

    def parse_number
      case current.literal
      when Float64
        AST::Number.new(current.literal.not_nil!.to_f64)
      else
        raise Error::Syntax::IncorrectType.new(current, "float64", "string")
      end
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

    def parse_array
      consume_if_nxt_is(TokenKind::NEW_LINE)
      content = parse_array_content
      consume_if_nxt_is(TokenKind::NEW_LINE)
      AST::ArrayList.new(content)
    end

    def parse_array_content
      items = [] of AST::Expression

      # empty array
      if nxt.kind == TokenKind::RIGHT_BRACKET
        consume
        return items
      end

      consume

      expr = parse_expr_recursively

      unless expr.nil?
        items << expr.not_nil!
      end

      consume_if_nxt_is(TokenKind::NEW_LINE)

      while nxt.kind == TokenKind::COMMA
        consume
        consume_if_nxt_is(TokenKind::NEW_LINE)
        consume

        expr = parse_expr_recursively

        unless expr.nil?
          items << expr.not_nil!
        end
        consume_if_nxt_is(TokenKind::NEW_LINE)
      end

      consume_if_nxt_is(TokenKind::RIGHT_BRACKET)
      items
    end

    def parse_json
      consume_if_nxt_is(TokenKind::NEW_LINE)
      content = parse_json_content
      consume_if_nxt_is(TokenKind::NEW_LINE)
      AST::Json.new(content)
    end

    def parse_json_content
      pairs = {} of String => AST::Expression

      # empty object
      if nxt.kind == TokenKind::RIGHT_CURLY
        consume
        return pairs
      end

      pairs.merge!(parse_json_pair)

      while nxt.kind == TokenKind::COMMA
        consume
        consume_if_nxt_is(TokenKind::NEW_LINE)
        pairs.merge!(parse_json_pair)
      end

      consume_if_nxt_is(TokenKind::RIGHT_CURLY)
      pairs
    end

    def parse_json_pair
      pair = {} of String => AST::Expression
      # find key
      key = ""
      consume

      if maybe_key = parse_expr_recursively
        raise "Json structure must have a String as a key not: #{maybe_key.class}" if maybe_key.class != AST::Str
        key = maybe_key.not_nil!.value.as(String)
        pair[key] = AST::Nil.new
      end

      # find value
      if nxt.kind == TokenKind::COLON
        consume
        consume_if_nxt_is(TokenKind::NEW_LINE)
        consume

        if value = parse_expr_recursively
          pair[key] = value.not_nil!.as(AST::Expression)
        end
      end

      pair
    end

    def parse_module_definition
      return unless consume_if_nxt_is(TokenKind::IDENTIFIER)
      mod = AST::ModuleDefinition.new(AST::Identifier.new(current.lexeme))

      if nxt.kind != TokenKind::NEW_LINE
        unexpected_token_error
        return
      end

      return unless consume_if_nxt_is(TokenKind::NEW_LINE)
      mod.body = parse_block

      # put module name onto fn_def for later use
      if body = mod.body
        body.expressions.each do |expr|
          if expr.is_a?(AST::FunctionDefinition)
            expr.module_name = mod.name
          end
        end
      end

      mod
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
      case identifier
      when AST::Identifier
        AST::FunctionCall.new(identifier.as(AST::Identifier), (parse_function_call_args || [] of AST::Expression), [] of AST::Identifier)
      when AST::QualifiedIdentifier
        fn_name = identifier.qualifiers.last
        qualifiers = identifier.qualifiers
        AST::FunctionCall.new(fn_name, (parse_function_call_args || [] of AST::Expression), qualifiers)
      end
    end

    def parse_function_call_args
      args = [] of AST::Expression

      # Function call without arguments.
      if nxt.kind == TokenKind::RIGHT_PAREN
        consume
        return args
      end

      consume
      expr = parse_expr_recursively
      unless expr.nil?
        args << expr.not_nil!
      end

      while nxt.kind == TokenKind::COMMA
        consume(2)
        expr = parse_expr_recursively
        unless expr.nil?
          args << expr.not_nil!
        end
      end

      return unless consume_if_nxt_is(TokenKind::RIGHT_PAREN)
      args.not_nil!
    end

    def parse_conditional
      conditional = AST::Conditional.new
      consume
      conditional.condition = parse_expr_recursively
      return unless consume_if_nxt_is(TokenKind::NEW_LINE)

      conditional.when_true = parse_block

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
             when TokenKind::LEFT_BRACKET
               parse_array
             when TokenKind::FN
               parse_function_definition
             when TokenKind::MOD
               parse_module_definition
             when TokenKind::IF
               parse_conditional
             when TokenKind::WHILE
               parse_repetition
             when TokenKind::LEFT_PAREN
               parse_grouped_expr
             when TokenKind::EXTERNAL_CODE
               parse_external_code
             when TokenKind::LEFT_CURLY
               parse_json
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

      # When expr is nil, it means we have reached a \n or an eof
      return if expr.nil?

      # Note that here we are checking the NEXT token.
      while nxt_not_terminator? && precedence < nxt_precedence
        expr = if (BINARY_OPERATORS + LOGICAL_OPERATORS).includes?(nxt.kind)
                 consume
                 parse_binary_operator(expr)
               elsif nxt.kind == TokenKind::LEFT_PAREN
                 consume
                 fn_call = parse_function_call(expr)
                 @function_calls << fn_call unless fn_call.nil?

                 if nxt.kind == TokenKind::TRIANGLE || lookahead(2).kind == TokenKind::TRIANGLE
                   if @chain.nil?
                     @chain = AST::FunctionChain.new
                   end
                 else
                   if @function_calls.size > 1
                     if @chain
                       @chain.not_nil!.function_calls = @function_calls.dup
                       @function_calls.clear
                     end

                     nil
                   else
                     @function_calls.clear
                     fn_call
                   end
                 end
               else
                 return expr
               end
      end
      expr
    end
  end
end
