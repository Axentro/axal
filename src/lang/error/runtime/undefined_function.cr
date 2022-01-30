module Axal::Error
  module Runtime
    class UndefinedFunction < Exception
      def initialize(fn_name)
        super("Undefined function #{fn_name}")
      end
    end
  end
end
