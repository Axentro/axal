module Axal::Error
  module Runtime
    class UnexpectedReturn < Exception
      def initialize
        super("Unexpected return")
      end
    end
  end
end
