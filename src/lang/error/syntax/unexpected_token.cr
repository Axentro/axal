module Axal::Error
  module Syntax
    class UnexpectedToken < Exception
      getter current_token : Token
      getter next_token : Token
      getter expected_token_kind : TokenKind?

      def initialize(@current_token, @next_token, @expected_token_kind = nil)
        message = "Unexpected token '#{@next_token.lexeme}' (#{@next_token.kind}) after '#{@current_token.lexeme}' (#{@current_token.kind})"
        message += "\nExpected: #{@expected_token_kind.not_nil!}" unless @expected_token_kind.nil?
        super(message)
      end
    end
  end
end
