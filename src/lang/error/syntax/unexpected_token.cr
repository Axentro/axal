module Axal::Error
  module Syntax
    class UnexpectedToken < Exception
      getter current_token : Token
      getter next_token : Token
      getter expected_token : Token?

      def initialize(@current_token, @next_token, @expected_token = nil)
        message = "Unexpected token #{@next_token.lexeme} after #{@current_token.lexeme}"
        message += "\nExpected: #{@expected_token.lexeme}" unless @expected_token.nil?
        super(message)
      end
    end
  end
end
