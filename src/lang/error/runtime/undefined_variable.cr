module Axal::Error
  module Runtime
    class UndefinedVariable < Exception
      def initialize(variable_name)
        super("Undefined variable #{variable_name}")
      end
    end
  end
end
