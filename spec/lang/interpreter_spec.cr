require "../spec_helper"

describe Interpreter do
  describe "interpret" do
    context "arithmetic expressions" do
      it "correctly evaluates a simple arithmetic expression" do
        interpreter = Interpreter.new

        interpreter.interpret(ast_from_source("arithmetic_expr_ok_1.axal"))

        interpreter.output.size.should eq(1)
        interpreter.output.first.should eq("4.0")
      end

      it "correctly evaluates a complex arithmetic expression" do
        interpreter = Interpreter.new

        interpreter.interpret(ast_from_source("arithmetic_expr_ok_2.axal"))

        interpreter.output.size.should eq(1)
        interpreter.output.first.should eq("5.0")
      end

      it "correctly evaluates a arithmetic expression with unary operators" do
        interpreter = Interpreter.new

        interpreter.interpret(ast_from_source("arithmetic_expr_ok_3.axal"))

        interpreter.output.size.should eq(1)
        interpreter.output.first.should eq("3.0")
      end
    end

    context "variable bindings" do
      it "does correctly assign and reassign values to a variable" do
        interpreter = Interpreter.new

        interpreter.interpret(ast_from_source("var_binding_ok_1.axal"))

        interpreter.output.size.should eq(2)
        interpreter.output[0].should eq("-2.0")
        interpreter.output[1].should eq("hey")
        interpreter.env["my_var"].should eq("hey")
      end

      it "assigns a function definition to a global variable" do
        interpreter = Interpreter.new

        interpreter.interpret(ast_from_source("var_binding_ok_2.axal"))
        interpreter.output.size.should eq(1)
        interpreter.output.first.should eq("2.0")
      end

      it "assigns a function definition to a function parameter" do
        interpreter = Interpreter.new

        interpreter.interpret(ast_from_source("var_binding_ok_3.axal"))
        interpreter.output.size.should eq(1)
        interpreter.output.first.should eq("2.0")
      end

      it "another variable binding with function definition" do
        interpreter = Interpreter.new

        interpreter.interpret(ast_from_source("var_binding_ok_4.axal"))
        interpreter.output.size.should eq(1)
        interpreter.output.first.should eq("3.0")
      end
    end

    context "module definitions" do
      it "correctly define a module" do
        interpreter = Interpreter.new

        interpreter.interpret(ast_from_source("mod_call_ok_1.axal"))

        interpreter.output.size.should eq(1)
        interpreter.output.first.should eq("true")
      end
    end

    context "function definitions" do
      it "does correctly define a function" do
        interpreter = Interpreter.new

        interpreter.interpret(ast_from_source("fn_def_ok_1.axal"))

        interpreter.output.size.should eq(1)
        interpreter.output.first.should eq("0.0")
      end
    end

    context "function calls" do
      it "does correctly call a defined function" do
        interpreter = Interpreter.new

        interpreter.interpret(ast_from_source("fn_call_ok_1.axal"))

        interpreter.env["result"].should eq("my_fn was called.")
      end

      it "does raise an error if the function was not defined" do
        interpreter = Interpreter.new

        expect_raises(Error::Runtime::UndefinedFunction) do
          interpreter.interpret(ast_from_source("fn_call_err_1.axal"))
        end
      end

      it "does raise an error if the function was called before its definition" do
        interpreter = Interpreter.new

        expect_raises(Error::Runtime::UndefinedFunction) do
          interpreter.interpret(ast_from_source("fn_call_err_2.axal"))
        end
      end

      it "does raise an error when the wrong number of arguments is given" do
        interpreter = Interpreter.new

        expect_raises(Error::Runtime::WrongNumArg) do
          interpreter.interpret(ast_from_source("fn_call_err_3.axal"))
        end
      end
    end

    context "recursive function calls" do
      it "does correctly handle recursive function calls" do
        interpreter = Interpreter.new

        interpreter.interpret(ast_from_source("recursion_ok_1.axal"))

        interpreter.env["f12"].should eq(144.0)
      end
    end

    context "scope of variables" do
      it "does assign to an existing global variable when inside a function" do
        interpreter = Interpreter.new

        interpreter.interpret(ast_from_source("scope_ok_1.axal"))

        interpreter.env["my_global_var"].should eq("Value given inside my_func()")
      end

      it "does declare and assign to a local variable when there is no global with the same name" do
        interpreter = Interpreter.new

        expect_raises(Error::Runtime::UndefinedVariable) do
          interpreter.interpret(ast_from_source("scope_ok_2.axal"))
        end
        interpreter.output.size.should eq(1)
        interpreter.output[0].should eq("A local variable")
      end

      it "does create a local var for each function param when there is no global using the same names" do
        interpreter = Interpreter.new

        expect_raises(Error::Runtime::UndefinedVariable) do
          interpreter.interpret(ast_from_source("scope_ok_3.axal"))
        end
        interpreter.env["param_3"].should eq("A global var")
        interpreter.output.size.should eq(2)
        interpreter.output[0].should eq("param_1")
        interpreter.output[1].should eq("param_2")
      end

      it "does not assign to a global var when a param uses the same name of an existing global var" do
        interpreter = Interpreter.new

        interpreter.interpret(ast_from_source("scope_ok_4.axal"))

        interpreter.output.size.should eq(4)
        interpreter.output[0].should eq("A global var")
        interpreter.output[1].should eq("fn call arg 1")
        interpreter.output[2].should eq("fn call arg 2")
        interpreter.output[3].should eq("A global var")

        interpreter.env.has_key?("param_2").should eq(false)
      end
    end

    context "return" do
      it "does correctly abort a function evaluation when a return is detected" do
        interpreter = Interpreter.new

        interpreter.interpret(ast_from_source("return_ok_1.axal"))

        interpreter.env["result"].should eq(true)
      end

      it "does correctly handle multiple functions returning one after another" do
        interpreter = Interpreter.new

        interpreter.interpret(ast_from_source("return_ok_2.axal"))

        interpreter.env["result"].should eq(true)
      end

      it "does raise an error when a return is used outside a function" do
        interpreter = Interpreter.new

        expect_raises(Error::Runtime::UnexpectedReturn) do
          interpreter.interpret(ast_from_source("return_err_1.axal"))
        end
      end
    end

    context "conditionals with empty blocks" do
      it "does evaluate the conditional to nil" do
        interpreter = Interpreter.new

        interpreter.interpret(ast_from_source("conditional_ok_13.axal"))

        interpreter.env["cond_result"]?.should be_nil
      end
    end

    context "conditionals having only an IF block" do
      it "does not evaluate the IF block when the condition is false" do
        interpreter = Interpreter.new

        interpreter.interpret(ast_from_source("conditional_ok_1.axal"))

        interpreter.output.size.should eq(0)
      end

      it "does not evaluate the IF block when the condition is falsey" do
        interpreter = Interpreter.new

        interpreter.interpret(ast_from_source("conditional_ok_2.axal"))

        interpreter.output.size.should eq(0)
      end

      it "does evaluate the IF block when the condition is true" do
        interpreter = Interpreter.new

        interpreter.interpret(ast_from_source("conditional_ok_3.axal"))

        interpreter.output.size.should eq(1)
        interpreter.output.first.should eq("IF block evaluated.")
      end

      it "does evaluate the IF block when the condition is truthy" do
        interpreter = Interpreter.new

        interpreter.interpret(ast_from_source("conditional_ok_4.axal"))

        interpreter.output.size.should eq(1)
        interpreter.output.first.should eq("IF block evaluated.")
      end
    end

    context "conditionals having IF / ELSE blocks" do
      it "does evaluate the IF block when the condition is truthy" do
        interpreter = Interpreter.new

        interpreter.interpret(ast_from_source("conditional_ok_5.axal"))

        interpreter.output.size.should eq(1)
        interpreter.output.first.should eq("IF block evaluated.")
      end

      it "does evaluate the ELSE block when the condition is falsey - example 1" do
        interpreter = Interpreter.new

        interpreter.interpret(ast_from_source("conditional_ok_6.axal"))

        interpreter.output.size.should eq(1)
        interpreter.output.first.should eq("ELSE block evaluated.")
      end

      it "does evaluate the ELSE block when the condition is falsey - example 2" do
        interpreter = Interpreter.new

        interpreter.interpret(ast_from_source("conditional_ok_16.axal"))

        interpreter.output.size.should eq(1)
        interpreter.output.first.should eq("The number is less than or equal to zero.")
      end
    end

    context "conditionals using logical operators" do
      it "does evaluate the IF block when an expression using AND is truthy" do
        interpreter = Interpreter.new

        interpreter.interpret(ast_from_source("conditional_ok_7.axal"))

        interpreter.output.size.should eq(1)
        interpreter.output.first.should eq("IF block evaluated.")
      end

      it "does evaluate the ELSE block when an expression using AND is falsey" do
        interpreter = Interpreter.new

        interpreter.interpret(ast_from_source("conditional_ok_8.axal"))

        interpreter.output.size.should eq(1)
        interpreter.output.first.should eq("ELSE block evaluated.")
      end

      it "does short-circuit when the left operand of AND is falsey" do
        interpreter = Interpreter.new

        interpreter.interpret(ast_from_source("conditional_ok_14.axal"))

        interpreter.output.size.should eq(0)
      end

      it "does evaluate the IF block when an expression using OR is truthy" do
        interpreter = Interpreter.new

        interpreter.interpret(ast_from_source("conditional_ok_9.axal"))

        interpreter.output.size.should eq(1)
        interpreter.output.first.should eq("IF block evaluated.")
      end

      it "does evaluate the ELSE block when an expression using OR is falsey" do
        interpreter = Interpreter.new

        interpreter.interpret(ast_from_source("conditional_ok_10.axal"))

        interpreter.output.size.should eq(1)
        interpreter.output.first.should eq("ELSE block evaluated.")
      end

      it "does short-circuit when the left operand of OR is truthy" do
        interpreter = Interpreter.new

        interpreter.interpret(ast_from_source("conditional_ok_15.axal"))

        interpreter.output.size.should eq(0)
        interpreter.env["short_circuited"].should eq(true)
      end

      it "does correctly interpret conditionals using both AND and OR" do
        interpreter = Interpreter.new

        interpreter.interpret(ast_from_source("conditional_ok_12.axal"))

        interpreter.output.size.should eq(1)
        interpreter.output.first.should eq("IF block evaluated.")
      end
    end

    context "nested conditionals" do
      it "does correctly interpret nested conditionals" do
        interpreter = Interpreter.new

        interpreter.interpret(ast_from_source("conditional_ok_11.axal"))

        interpreter.output.size.should eq(1)
        interpreter.output.first.should eq("ELSE IF block evaluated.")
      end
    end

    context "repetitions (aka loops)" do
      it "does correctly evaluate a repetition" do
        interpreter = Interpreter.new

        interpreter.interpret(ast_from_source("repetition_ok_1.axal"))

        interpreter.env["i"].should eq(9.0)
      end

      it "does correctly evaluate a repetition with a complex condition" do
        interpreter = Interpreter.new

        interpreter.interpret(ast_from_source("repetition_ok_2.axal"))

        interpreter.env["i"].should eq(5.0)
        interpreter.env["continue_loop"].should eq(false)
      end
    end

    context "complex programs" do
      it "does correctly interpret an integer summation program" do
        interpreter = Interpreter.new

        interpreter.interpret(ast_from_source("complex_program_ok_1.axal"))

        interpreter.output.size.should eq(1)
        interpreter.output.first.should eq("5050.0")
      end
    end

    context "arrays" do
      it "correctly interprets arrays" do
        interpreter = Interpreter.new

        interpreter.interpret(ast_from_source("array_ok_1.axal"))

        interpreter.output.size.should eq(1)
        interpreter.output.first.should eq("[1.0, 2.0, 3.0, [5.0, 6.0]]")
      end
    end

    context "external code" do
      it "correctly interprets standalone external code" do
        interpreter = Interpreter.new

        interpreter.interpret(ast_from_source("external_code_ok_1.axal"))

        interpreter.output.size.should eq(1)
        interpreter.output.first.should eq("2.0")
      end
      it "correctly process external code with local variables" do
        interpreter = Interpreter.new

        interpreter.interpret(ast_from_source("external_code_ok_2.axal"))

        interpreter.output.size.should eq(1)
        interpreter.output.first.should eq("2.0")
      end
      it "correctly process external code with global variables" do
        interpreter = Interpreter.new

        interpreter.interpret(ast_from_source("external_code_ok_3.axal"))

        interpreter.output.size.should eq(1)
        interpreter.output.first.should eq("2.0")
      end
    end

    it "x" do
      interpreter = Interpreter.new
      interpreter.interpret(ast_from_source("x.axal"))
      pp interpreter.output
    end
  end
end

def ast_from_source(filename)
  source = File.read("#{__DIR__}/../fixtures/interpreter/#{filename}")
  lexer = Lexer.new(source)
  parser = Parser.new(lexer.start_tokenization)
  parser.parse

  parser.ast
end
