module Axal::Error
  module Syntax
    class IncorrectType < Exception
      def initialize(current_token : Token, expected_type : String, actual_type : String)
        super("Incorrect type for #{current_token.kind}, expected: #{expected_type} but was: #{actual_type}")
      end
    end
  end
end
