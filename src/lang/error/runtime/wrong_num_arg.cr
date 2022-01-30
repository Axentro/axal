module Axal::Error
  module Runtime
    class WrongNumArg < Exception
      def initialize(fn_name, num_arg_given, num_arg_expected)
        super("#{fn_name}(): wrong number of arguments (given #{num_arg_given}, expected #{num_arg_expected})")
      end
    end
  end
end
