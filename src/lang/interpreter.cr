module Axal
  class Interpreter
    getter program : AST::Program? = nil
    getter output : Array(String)
    getter env : Hash(String, (AST::Expression | X))
    property unwind_call_stack : Int32

    def initialize
      @output = [] of String
      @env = {} of String => AST::Expression | X
      @call_stack = [] of Runtime::StackFrame
      @unwind_call_stack = -1
    end

    def interpret(ast)
      @program = ast

      interpret_nodes(@program.not_nil!.expressions)
    end

    def interpret_nodes(nodes)
      last_value = nil

      nodes.each do |node|
        last_value = interpret_node(node)

        if return_detected?(node)
          raise Error::Runtime::UnexpectedReturn.new unless @call_stack.size > 0

          @unwind_call_stack = @call_stack.size # We store the current stack level to know when to stop returning.
          return last_value
        end

        if @unwind_call_stack == @call_stack.size
          # We are still inside a function that returned, so we keep on bubbling up from its structures (e.g., conditionals, loops etc).
          return last_value
        elsif @unwind_call_stack > @call_stack.size
          # We returned from the function, so we reset the "unwind indicator".
          @unwind_call_stack = -1
        end
      end

      last_value
    end

    def interpret_node(node)
      # pp node
      case node
      when AST::ModuleDefinition
        interpret_module_definition(node.as(AST::ModuleDefinition))
      when AST::FunctionCall
        interpret_function_call(node.as(AST::FunctionCall))
      when AST::FunctionDefinition
        interpret_function_definition(node.as(AST::FunctionDefinition))
      when AST::BinaryOperator
        interpret_binary_operator(node.as(AST::BinaryOperator))
      when AST::Boolean
        interpret_boolean(node.as(AST::Boolean))
      when AST::Conditional
        interpret_conditional(node.as(AST::Conditional))
      when AST::Identifier
        interpret_identifier(node.as(AST::Identifier))
      when AST::Nil
        interpret_nil(node.as(AST::Nil))
      when AST::Number
        interpret_number(node.as(AST::Number))
      when AST::Repetition
        interpret_repetition(node.as(AST::Repetition))
      when AST::Return
        interpret_return(node.as(AST::Return))
      when AST::Str
        interpret_string(node.as(AST::Str))
      when AST::ExternalCode
        interpret_external_code(node.as(AST::ExternalCode))
      when AST::UnaryOperator
        interpret_unary_operator(node.as(AST::UnaryOperator))
      when AST::VarBinding
        interpret_var_binding((node.as(AST::VarBinding)))
      when AST::ArrayList
        interpret_array_list(node.as(AST::ArrayList))
      when AST::FunctionChain
        interpret_function_chain(node.as(AST::FunctionChain))
      end
    end

    def fetch_function_definition(fn_name : String)
      fn_def = if @call_stack.size > 0 && @call_stack.last.env.has_key?(fn_name)
                 # Local variable.
                 @call_stack.last.env[fn_name]
               elsif @env.has_key?(fn_name)
                 # Global variable.
                 @env[fn_name]
               end

      raise Error::Runtime::UndefinedFunction.new(fn_name) if fn_def.nil?

      fn_def.as(AST::FunctionDefinition)
    end

    def fetch_ext_code_replacement_value(param)
      # First process local variables and if not found locally find globals
      if @call_stack.size > 0 && @call_stack.last.env.has_key?(param)
        # Local variable.
        @call_stack.last.env[param]
      elsif @env.has_key?(param)
        # Global variable.
        @env[param]
      else
        # Undefined variable.
        raise Error::Runtime::UndefinedVariable.new(param)
      end
    end

    def assign_function_args_to_params(stack_frame)
      fn_def = stack_frame.fn_def.as(AST::FunctionDefinition)
      fn_call = stack_frame.fn_call.as(AST::FunctionCall)

      given = fn_call.args.size
      expected = fn_def.params.size
      if given != expected
        raise Error::Runtime::WrongNumArg.new(fn_def.function_name_as_str, given, expected)
      end

      # Applying the values passed in this particular function call to the respective defined parameters.
      # Always assign a local variable for each param
      if fn_def.params != nil
        fn_def.params.each_with_index do |param, i|
          stack_frame.env[param.name] = interpret_node(fn_call.args[i]).as(X | AST::FunctionDefinition)
        end
      end
    end

    def interpret_function_chain(chain : AST::FunctionChain)
      fcs = chain.function_calls

      # can only chain println as the last one - raise error if println is not last
      fcs.map_with_index { |fc, i| {name: fc.name.name, pos: i + 1} }.select { |np| np[:name] == "println" }
        .each { |np| raise "println function must be last in the chain (currently position #{np[:pos]})" if np[:pos] != fcs.size }

      current_result = nil
      fcs.in_groups_of(2).each_with_index do |grp, i|
        if i == 0
          current_result = interpret_function_call(grp.first.not_nil!)
          current_result = interpret_chained_function_call(grp.last.not_nil!, current_result.not_nil!)
        else
          current_result = interpret_chained_function_call(grp.first.not_nil!, current_result.not_nil!)
          if !grp.last.nil?
            current_result = interpret_chained_function_call(grp.last.not_nil!, current_result.not_nil!)
          end
        end
      end
      current_result.not_nil!
    end

    def interpret_chained_function_call(fn_call : AST::FunctionCall, param1)
      if fn_call.function_name_as_str == "println"
        return println_chained(param1)
      end

      fn_def = fetch_function_definition(fn_call.function_name_as_str)

      stack_frame = Runtime::StackFrame.new(fn_def, fn_call)

      assign_function_args_to_params_for_chained_call(stack_frame, param1)

      # Executing the function body.
      @call_stack << stack_frame
      value = interpret_nodes(fn_def.body.not_nil!.expressions)
      @call_stack.pop
      value
    end

    def assign_function_args_to_params_for_chained_call(stack_frame, param1)
      fn_def = stack_frame.fn_def.as(AST::FunctionDefinition)
      fn_call = stack_frame.fn_call.as(AST::FunctionCall)

      given = fn_call.args.size + 1
      expected = fn_def.params.size
      if given != expected
        raise Error::Runtime::WrongNumArg.new(fn_def.function_name_as_str, given, expected)
      end

      # Applying the values passed in this particular function call to the respective defined parameters.
      # Pass the result of the previous function
      if fn_def.params != nil
        fn_def.params.each_with_index do |param, i|
          if i == 0
            stack_frame.env[param.name] = param1.as(X)
          else
            stack_frame.env[param.name] = interpret_node(fn_call.args[i - 1]).as(X | AST::FunctionDefinition)
          end
        end
      end
    end

    def return_detected?(node)
      node.type == "return"
    end

    def interpret_identifier(identifier)
      # First process local variables and if not found locally find globals
      if @call_stack.size > 0 && @call_stack.last.env.has_key?(identifier.name)
        # Local variable.
        @call_stack.last.env[identifier.name]
      elsif @env.has_key?(identifier.name)
        # Global variable.
        @env[identifier.name]
      else
        # Undefined variable.
        raise Error::Runtime::UndefinedVariable.new(identifier.name)
      end
    end

    def interpret_var_binding(var_binding)
      expr = interpret_node(var_binding.right.not_nil!)
      if @call_stack.size > 0
        # We are inside a function. If the name points to a global var, we assign the value to it.
        # Otherwise, we create and / or assign to a local var.
        if @env.has_key?(var_binding.var_name_as_str)
          @env[var_binding.var_name_as_str] = expr.as(X | AST::FunctionDefinition | AST::FunctionChain)
        else
          @call_stack.last.env[var_binding.var_name_as_str] = expr.as(X | AST::FunctionDefinition | AST::FunctionChain)
        end
      else
        # We are not inside a function. Therefore, we create and / or assign to a global var.
        @env[var_binding.var_name_as_str] = expr.as(X | AST::FunctionDefinition | AST::FunctionChain)
      end
    end

    # TODO Empty blocks are accepted both for the IF and for the ELSE. For the IF, the parser returns a block with an empty collection of expressions. For the else, no block is constructed. The evaluation is already resulting in nil, which is the desired behavior. It would be better, however, if the parser also returned a block with no expressions for an ELSE with an empty block, as is the case in an IF with an empty block. Investigate this nuance of the parser in the future.
    def interpret_conditional(conditional)
      evaluated_cond = interpret_node(conditional.condition.not_nil!)

      # We could implement the line below in a shorter way, but better to be explicit about truthiness in Stoffle.
      if evaluated_cond == nil || evaluated_cond == false
        return nil if conditional.when_false.nil?

        interpret_nodes(conditional.when_false.not_nil!.expressions)
      else
        interpret_nodes(conditional.when_true.not_nil!.expressions)
      end
    end

    def interpret_repetition(repetition)
      while interpret_node(repetition.condition.not_nil!)
        interpret_nodes(repetition.block.not_nil!.expressions)
      end
    end

    def interpret_function_definition(fn_def)
      @env[fn_def.function_name_as_str] = fn_def
    end

    def interpret_module_definition(mod_def)
      @env[mod_def.module_name_as_str] = mod_def
      # process all the expressions inside the module body
      interpret_nodes(mod_def.body.not_nil!.expressions) if !mod_def.body.nil?
    end

    def interpret_function_call(fn_call : AST::FunctionCall)
      return if println(fn_call)
      fn_def = fetch_function_definition(fn_call.function_name_as_str)

      stack_frame = Runtime::StackFrame.new(fn_def, fn_call)

      assign_function_args_to_params(stack_frame)

      # Executing the function body.
      @call_stack << stack_frame
      value = interpret_nodes(fn_def.body.not_nil!.expressions)
      @call_stack.pop
      value
    end

    def interpret_return(ret)
      interpret_node(ret.expression.not_nil!) unless ret.expression.nil?
    end

    def interpret_unary_operator(unary_op)
      expr = interpret_node(unary_op.operand.not_nil!)
      case unary_op.operator
      when TokenKind::HYPHEN
        case expr
        when Float64
          -expr
        else
          raise "unary operator can only apply to a number"
        end
      else # "!"
        case expr
        when Float64, Bool
          !expr
        else
          raise "ooops unary can only apply to number or boolean"
        end
      end
    end

    def interpret_binary_operator(binary_op)
      lhs = interpret_node(binary_op.left.not_nil!)

      if binary_op.operator == TokenKind::OR
        lhs || interpret_node(binary_op.right.not_nil!).as(X)
      elsif binary_op.operator == TokenKind::AND
        lhs && interpret_node(binary_op.right.not_nil!).as(X)
      elsif binary_op.operator == TokenKind::DOUBLE_EQUALS
        lhs == interpret_node(binary_op.right.not_nil!).as(X)
      else
        rhs = interpret_node(binary_op.right.not_nil!)
        if lhs.is_a?(Float64) && rhs.is_a?(Float64)
          case binary_op.operator
          when TokenKind::PLUS
            lhs + rhs
          when TokenKind::HYPHEN
            lhs - rhs
          when TokenKind::ASTERISK
            lhs * rhs
          when TokenKind::FORWARD_SLASH
            lhs / rhs
          when TokenKind::NOT_EQUAL
            lhs != rhs
          when TokenKind::GREATER_THAN
            lhs > rhs
          when TokenKind::LESS_THAN
            lhs < rhs
          when TokenKind::GREATER_THAN_OR_EQUAL
            lhs >= rhs
          when TokenKind::LESS_THAN_OR_EQUAL
            lhs <= rhs
          else
            raise "The operator '#{binary_op.operator.to_s}' can only be applied to 2 numbers (not #{lhs.class} and #{rhs.class})"
          end
        elsif lhs.is_a?(String) && rhs.is_a?(String)
          case binary_op.operator
          when TokenKind::PLUS
            lhs + rhs
          when TokenKind::NOT_EQUAL
            lhs != rhs
          when TokenKind::GREATER_THAN
            lhs > rhs
          when TokenKind::LESS_THAN
            lhs < rhs
          when TokenKind::GREATER_THAN_OR_EQUAL
            lhs >= rhs
          when TokenKind::LESS_THAN_OR_EQUAL
            lhs <= rhs
          else
            raise "The operator '#{binary_op.operator.to_s}' can only be applied to 2 strings (not #{lhs.class} and #{rhs.class})"
          end
        else
          raise "The operator '#{binary_op.operator.to_s}' cannot be applied to (#{lhs.class} and #{rhs.class})"
        end
      end
    end

    def interpret_binary_operator2(binary_op)
      lhs = interpret_node(binary_op.left.not_nil!)

      if binary_op.operator == TokenKind::OR
        if lhs.is_a?(Bool)
          lhs || interpret_node(binary_op.right.not_nil!)
        elsif lhs.is_a?(String)
          lhs || interpret_node(binary_op.right.not_nil!)
        elsif lhs.is_a?(Float64)
          lhs || interpret_node(binary_op.right.not_nil!)
        elsif lhs.is_a?(Nil)
          lhs || interpret_node(binary_op.right.not_nil!)
        end
      elsif binary_op.operator == TokenKind::AND
        if lhs.is_a?(Bool)
          lhs && interpret_node(binary_op.right.not_nil!)
        elsif lhs.is_a?(String)
          lhs && interpret_node(binary_op.right.not_nil!)
        elsif lhs.is_a?(Float64)
          lhs && interpret_node(binary_op.right.not_nil!)
        elsif lhs.is_a?(Nil)
          lhs && interpret_node(binary_op.right.not_nil!)
        end
      elsif binary_op.operator == TokenKind::DOUBLE_EQUALS
        if lhs.is_a?(Bool)
          lhs == interpret_node(binary_op.right.not_nil!)
        elsif lhs.is_a?(String)
          lhs == interpret_node(binary_op.right.not_nil!)
        elsif lhs.is_a?(Float64)
          lhs == interpret_node(binary_op.right.not_nil!)
        elsif lhs.is_a?(Nil)
          lhs == interpret_node(binary_op.right.not_nil!)
        end
      else
        rhs = interpret_node(binary_op.right.not_nil!)
        if lhs.is_a?(Float64) && rhs.is_a?(Float64)
          case binary_op.operator
          when TokenKind::PLUS
            lhs + rhs
          when TokenKind::HYPHEN
            lhs - rhs
          when TokenKind::ASTERISK
            lhs * rhs
          when TokenKind::FORWARD_SLASH
            lhs / rhs
          when TokenKind::NOT_EQUAL
            lhs != rhs
          when TokenKind::GREATER_THAN
            lhs > rhs
          when TokenKind::LESS_THAN
            lhs < rhs
          when TokenKind::GREATER_THAN_OR_EQUAL
            lhs >= rhs
          when TokenKind::LESS_THAN_OR_EQUAL
            lhs <= rhs
          else
            raise "The operator '#{binary_op.operator.to_s}' can only be applied to 2 numbers (not #{lhs.class} and #{rhs.class})"
          end
        elsif lhs.is_a?(String) && rhs.is_a?(String)
          case binary_op.operator
          when TokenKind::PLUS
            lhs + rhs
          when TokenKind::NOT_EQUAL
            lhs != rhs
          when TokenKind::GREATER_THAN
            lhs > rhs
          when TokenKind::LESS_THAN
            lhs < rhs
          when TokenKind::GREATER_THAN_OR_EQUAL
            lhs >= rhs
          when TokenKind::LESS_THAN_OR_EQUAL
            lhs <= rhs
          else
            raise "The operator '#{binary_op.operator.to_s}' can only be applied to 2 strings (not #{lhs.class} and #{rhs.class})"
          end
        else
          raise "The operator '#{binary_op.operator.to_s}' cannot be applied to (#{lhs.class} and #{rhs.class})"
        end
      end
    end

    def interpret_boolean(boolean)
      boolean.value
    end

    def interpret_nil(nil_node)
      nil
    end

    def interpret_number(number) : Float64
      v = number.value
      case v
      when Float64
        v.to_f64
      else
        raise "oops should be float64"
      end
    end

    def interpret_string(string)
      string.value
    end

    def interpret_array_list(array : AST::ArrayList) : X
      array.items.map do |item|
        case item
        when AST::ArrayList
          interpret_array_list(item).as(X)
        else
          interpret_node(item).as(X)
        end
      end
    end

    # find variables in the external code and fetch from local or global
    def interpret_external_code(external_code)
      rt = Duktape::Runtime.new(500)
      v = replace_external_code_variables(external_code.value.as(String))
      rt.eval(v)
    rescue e : Exception
      raise "external code error: #{e.message}"
    end

    def replace_external_code_variables(external_code)
      vars = external_code.scan(/\:(.+?)\:/)
      vars.each do |v|
        param = v[1]
        r = fetch_ext_code_replacement_value(param)
        external_code = external_code.gsub(":#{param}:", r)
      end
      external_code
    end

    def fetch_ext_code_replacement_value(param)
      # variables.map
      # First process local variables and if not found locally find globals
      if @call_stack.size > 0 && @call_stack.last.env.has_key?(param)
        # Local variable.
        @call_stack.last.env[param]
      elsif @env.has_key?(param)
        # Global variable.
        @env[param]
      else
        # Undefined variable.
        raise Error::Runtime::UndefinedVariable.new(param)
      end
    end

    # Built in functions
    def println_chained(result)
      output << result.to_s
      puts result
      true
    end

    def println(fn_call)
      return false if fn_call.function_name_as_str != "println"

      result = interpret_node(fn_call.args.first).to_s
      output << result
      puts result
      true
    end
  end
end
