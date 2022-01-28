module Axal::Error
  module Syntax
    class UnrecognizedToken < Exception
      getter unrecognized_token : Token

      def initialize(@unrecognized_token)
        message = "Unrecognized token #{@unrecognized_token.lexeme}"
        super(message)
      end
    end
  end
end
