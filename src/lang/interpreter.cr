module Axal
  class Interpreter
    getter program : AST::Program? = nil
    getter output : Array(String)
    getter env : Hash(String, (AST::Expression | Bool | Float64 | String | Nil))
    property unwind_call_stack : Int32

    def initialize
      @output = [] of String
      @env = {} of String => AST::Expression | Bool | Float64 | String | Nil
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
      when AST::UnaryOperator
        interpret_unary_operator(node.as(AST::UnaryOperator))
      when AST::VarBinding
        interpret_var_binding((node.as(AST::VarBinding)))
      end
    end

    def fetch_function_definition(fn_name : String)
      fn_def = @env[fn_name]?
      raise Error::Runtime::UndefinedFunction.new(fn_name) if fn_def.nil?

      fn_def.as(AST::FunctionDefinition)
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
      if fn_def.params != nil
        fn_def.params.each_with_index do |param, i|
          expr = interpret_node(fn_call.args[i])
          if @env.has_key?(param.name)
            # A global variable is already defined. We assign the passed in value to it.
            case expr
            when Float64
              @env[param.name] = expr.as(Float64)
            when String
              @env[param.name] = expr.as(String)
            when Bool
              @env[param.name] = expr.as(Bool)
            else
              raise "cant assign variable"
            end
            #   env[param.name] = interpret_node(fn_call.args[i].as(AST::Expression))
          else
            # A global variable with the same name doesn't exist. We create a new local variable.
            #   stack_frame.env[param.name] = interpret_node(fn_call.args[i])
            case expr
            when Float64
              stack_frame.env[param.name] = expr.as(Float64)
            when String
              stack_frame.env[param.name] = expr.as(String)
            when Bool
              stack_frame.env[param.name] = expr.as(Bool)
            else
              raise "cant assign variable"
            end
          end
        end
      end
    end

    def return_detected?(node)
      node.type == "return"
    end

    def interpret_identifier(identifier)
      if @env.has_key?(identifier.name)
        # Global variable.
        @env[identifier.name]
      elsif @call_stack.size > 0 && @call_stack.last.env.has_key?(identifier.name)
        # Local variable.
        @call_stack.last.env[identifier.name]
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
          case expr
          when Float64
            @env[var_binding.var_name_as_str] = expr.as(Float64)
          when String
            @env[var_binding.var_name_as_str] = expr.as(String)
          when Bool
            @env[var_binding.var_name_as_str] = expr.as(Bool)
          when Nil
            @env[var_binding.var_name_as_str] = expr.as(Nil)
          else
            raise "cant assign variable inside function for global var"
          end
        else
          case expr
          when Float64
            @call_stack.last.env[var_binding.var_name_as_str] = expr.as(Float64)
          when String
            @call_stack.last.env[var_binding.var_name_as_str] = expr.as(String)
          when Bool
            @call_stack.last.env[var_binding.var_name_as_str] = expr.as(Bool)
          when Nil
            @call_stack.last.env[var_binding.var_name_as_str] = expr.as(Nil)
          else
            raise "cant assign variable inside function for local var"
          end
        end
      else
        # We are not inside a function. Therefore, we create and / or assign to a global var.
        case expr
        when Float64
          @env[var_binding.var_name_as_str] = expr.as(Float64)
        when String
          @env[var_binding.var_name_as_str] = expr.as(String)
        when Bool
          @env[var_binding.var_name_as_str] = expr.as(Bool)
        when Nil
          @env[var_binding.var_name_as_str] = expr.as(Nil)
        else
          raise "cant assign variable outside function"
        end
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

    # Built in functions
    def println(fn_call)
      return false if fn_call.function_name_as_str != "println"

      result = interpret_node(fn_call.args.first).to_s
      output << result
      puts result
      true
    end
  end
end