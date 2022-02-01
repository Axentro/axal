require "../spec_helper"

describe Parser do
  axal_prog = AST::Program
  axal_expr = AST::Expression
  axal_var_binding = AST::VarBinding
  axal_ident = AST::Identifier
  axal_str = AST::Str
  axal_num = AST::Number
  axal_bool = AST::Boolean
  axal_nil = AST::Nil
  axal_return = AST::Return
  axal_unary_op = AST::UnaryOperator
  axal_binary_op = AST::BinaryOperator
  axal_conditional = AST::Conditional
  axal_repetition = AST::Repetition
  axal_block = AST::Block
  axal_fn_def = AST::FunctionDefinition
  axal_mod_def = AST::ModuleDefinition
  axal_fn_call = AST::FunctionCall
  axal_ext_code = AST::ExternalCode

  describe "parse" do
    context "variable binding" do
      it "generates the expected AST when the syntax is correct" do
        ident = axal_ident.new("my_var")
        num = axal_num.new(1.0)
        var_binding = axal_var_binding.new(ident, num)
        expected_program = axal_prog.new
        expected_program.expressions << var_binding

        parser = Parser.new(tokens_from_source("var_binding_ok_1.axal"))
        parser.parse

        parser.ast.should eq(expected_program)
      end

      it "results in a syntax error when the syntax is not respected" do
        parser = Parser.new(tokens_from_source("var_binding_err_1.axal"))
        parser.parse

        parser.errors.size.should eq(1)
        parser.errors.last.as(Error::Syntax::UnexpectedToken).next_token.lexeme.should eq("1")
      end
    end

    context "standalone identifier" do
      it "generates the expected AST" do
        ident = axal_ident.new("my_var")
        num = axal_num.new(1.0)
        var_binding = axal_var_binding.new(ident, num)
        expected_program = axal_prog.new
        expected_program.expressions << var_binding
        expected_program.expressions << ident

        parser = Parser.new(tokens_from_source("standalone_identifier_ok.axal"))
        parser.parse

        parser.ast.should eq(expected_program)
      end
    end

    context "standalone number" do
      it "generates the expected AST" do
        expected_program = axal_prog.new
        expected_program.expressions << axal_num.new(1991.0)
        expected_program.expressions << axal_num.new(7.0)
        expected_program.expressions << axal_num.new(28.28)

        parser = Parser.new(tokens_from_source("standalone_number_ok.axal"))
        parser.parse

        parser.ast.should eq(expected_program)
      end
    end

    context "standalone string" do
      it "generates the expected AST" do
        expected_program = axal_prog.new
        expected_program.expressions << axal_str.new("a string")
        expected_program.expressions << axal_str.new("another string")

        parser = Parser.new(tokens_from_source("standalone_string_ok.axal"))
        parser.parse

        parser.ast.should eq(expected_program)
      end
    end

    context "standalone boolean" do
      it "generates the expected AST" do
        expected_program = axal_prog.new
        expected_program.expressions << axal_bool.new(true)
        expected_program.expressions << axal_bool.new(false)

        parser = Parser.new(tokens_from_source("standalone_boolean_ok.axal"))
        parser.parse

        parser.ast.should eq(expected_program)
      end
    end

    context "boolean expressions" do
      it "generates the expected AST for 1 == 1" do
        expected_program = axal_prog.new
        comparison_op = axal_binary_op.new(TokenKind::DOUBLE_EQUALS, axal_num.new(1.0), axal_num.new(1.0))

        expected_program.expressions << comparison_op
        parser = Parser.new(tokens_from_source("boolean_expr_ok_7.axal"))
        parser.parse

        parser.ast.should eq(expected_program)
      end

      it "generates the expected AST for 2 != 1" do
        expected_program = axal_prog.new
        comparison_op = axal_binary_op.new(TokenKind::NOT_EQUAL, axal_num.new(2.0), axal_num.new(1.0))

        expected_program.expressions << comparison_op
        parser = Parser.new(tokens_from_source("boolean_expr_ok_6.axal"))
        parser.parse

        parser.ast.should eq(expected_program)
      end

      it "generates the expected AST for 2 + 2 > 3" do
        expected_program = axal_prog.new
        plus_op = axal_binary_op.new(TokenKind::PLUS, axal_num.new(2.0), axal_num.new(2.0))
        comparison_op = axal_binary_op.new(TokenKind::GREATER_THAN, plus_op, axal_num.new(3.0))

        expected_program.expressions << comparison_op
        parser = Parser.new(tokens_from_source("boolean_expr_ok_5.axal"))
        parser.parse

        parser.ast.should eq(expected_program)
      end

      it "generates the expected AST for 2 + 2 >= 3" do
        expected_program = axal_prog.new
        plus_op = axal_binary_op.new(TokenKind::PLUS, axal_num.new(2.0), axal_num.new(2.0))
        comparison_op = axal_binary_op.new(TokenKind::GREATER_THAN_OR_EQUAL, plus_op, axal_num.new(3.0))

        expected_program.expressions << comparison_op
        parser = Parser.new(tokens_from_source("boolean_expr_ok_4.axal"))
        parser.parse

        parser.ast.should eq(expected_program)
      end

      it "generates the expected AST for 3 < 2 + 2" do
        expected_program = axal_prog.new
        plus_op = axal_binary_op.new(TokenKind::PLUS, axal_num.new(2.0), axal_num.new(2.0))
        comparison_op = axal_binary_op.new(TokenKind::LESS_THAN, axal_num.new(3.0), plus_op)

        expected_program.expressions << comparison_op
        parser = Parser.new(tokens_from_source("boolean_expr_ok_3.axal"))
        parser.parse

        parser.ast.should eq(expected_program)
      end

      it "generate the expected AST for 3 <= 2 + 2" do
        expected_program = axal_prog.new
        plus_op = axal_binary_op.new(TokenKind::PLUS, axal_num.new(2.0), axal_num.new(2.0))
        comparison_op = axal_binary_op.new(TokenKind::LESS_THAN_OR_EQUAL, axal_num.new(3.0), plus_op)

        expected_program.expressions << comparison_op
        parser = Parser.new(tokens_from_source("boolean_expr_ok_2.axal"))
        parser.parse

        parser.ast.should eq(expected_program)
      end

      it "generates the expected AST for true != false" do
        expected_program = axal_prog.new
        not_eq_op = axal_binary_op.new(TokenKind::NOT_EQUAL, axal_bool.new(true), axal_bool.new(false))

        expected_program.expressions << not_eq_op
        parser = Parser.new(tokens_from_source("boolean_expr_ok_1.axal"))
        parser.parse

        parser.ast.should eq(expected_program)
      end
    end

    context "standalone nil" do
      it "generates the expected AST" do
        expected_program = axal_prog.new
        expected_program.expressions << axal_nil.new
        parser = Parser.new(tokens_from_source("standalone_nil_ok.axal"))
        parser.parse

        parser.ast.should eq(expected_program)
      end
    end

    context "unary operators" do
      it "generates the expected AST" do
        expected_program = axal_prog.new
        minus_op_1 = axal_unary_op.new(TokenKind::HYPHEN, axal_num.new(28.0))
        minus_op_2 = axal_unary_op.new(TokenKind::HYPHEN, axal_num.new(24.42))
        bang_op = axal_unary_op.new(TokenKind::EXCLAMATION, axal_num.new(7.0))
        expected_program.expressions << minus_op_1
        expected_program.expressions << minus_op_2
        expected_program.expressions << bang_op
        parser = Parser.new(tokens_from_source("unary_operator_ok.axal"))
        parser.parse

        parser.ast.should eq(expected_program)
      end
    end

    context "binary operators" do
      it "generates the expected AST for 2 + 2" do
        expected_program = axal_prog.new
        plus_op = axal_binary_op.new(TokenKind::PLUS, axal_num.new(2.0), axal_num.new(2.0))
        expected_program.expressions << plus_op
        parser = Parser.new(tokens_from_source("binary_operator_ok_1.axal"))
        parser.parse

        parser.ast.should eq(expected_program)
      end

      it "generates the expected AST for 2 + 2 * 3" do
        expected_program = axal_prog.new
        multiplication_op = axal_binary_op.new(TokenKind::ASTERISK, axal_num.new(2.0), axal_num.new(3.0))
        plus_op = axal_binary_op.new(TokenKind::PLUS, axal_num.new(2.0), multiplication_op)
        expected_program.expressions << plus_op
        parser = Parser.new(tokens_from_source("binary_operator_ok_2.axal"))
        parser.parse

        # expected: 2 + (2 * 3)
        parser.ast.should eq(expected_program)
      end

      it "does generate the expected AST for 2 + 2 * 3 / 3" do
        expected_program = axal_prog.new
        multiplication_op = axal_binary_op.new(TokenKind::ASTERISK, axal_num.new(2.0), axal_num.new(3.0))
        division_op = axal_binary_op.new(TokenKind::FORWARD_SLASH, multiplication_op, axal_num.new(3.0))
        plus_op = axal_binary_op.new(TokenKind::PLUS, axal_num.new(2.0), division_op)
        expected_program.expressions << plus_op
        parser = Parser.new(tokens_from_source("binary_operator_ok_3.axal"))

        parser.parse

        # expected: 2 + ((2 * 3) / 3)
        parser.ast.should eq(expected_program)
      end
    end

    context "mixed operators" do
      it "generates the expected AST for -10 + 2 + 2 * 3 / 3" do
        expected_program = axal_prog.new
        inversion_op = axal_unary_op.new(TokenKind::HYPHEN, axal_num.new(10.0))
        plus_op_1 = axal_binary_op.new(TokenKind::PLUS, inversion_op, axal_num.new(2.0))
        multiplication_op = axal_binary_op.new(TokenKind::ASTERISK, axal_num.new(2.0), axal_num.new(3.0))
        division_op = axal_binary_op.new(TokenKind::FORWARD_SLASH, multiplication_op, axal_num.new(3.0))
        plus_op_2 = axal_binary_op.new(TokenKind::PLUS, plus_op_1, division_op)
        expected_program.expressions << plus_op_2
        parser = Parser.new(tokens_from_source("mixed_operator_ok_1.axal"))

        parser.parse

        # expected: (-10 + 2) + ((2 * 3) / 3)
        parser.ast.should eq(expected_program)
      end
    end

    context "logical operators" do
      it "generates the expected AST for true and false" do
        expected_program = axal_prog.new
        and_op = axal_binary_op.new(TokenKind::AND, axal_bool.new(true), axal_bool.new(false))
        expected_program.expressions << and_op
        parser = Parser.new(tokens_from_source("logical_operator_ok_1.axal"))

        parser.parse

        parser.ast.should eq(expected_program)
      end

      it "does generate the expected AST for true or false" do
        expected_program = axal_prog.new
        or_op = axal_binary_op.new(TokenKind::OR, axal_bool.new(true), axal_bool.new(false))
        expected_program.expressions << or_op
        parser = Parser.new(tokens_from_source("logical_operator_ok_2.axal"))

        parser.parse

        parser.ast.should eq(expected_program)
      end

      it "does generate the expected AST for true and false or true" do
        expected_program = axal_prog.new
        and_op = axal_binary_op.new(TokenKind::AND, axal_bool.new(true), axal_bool.new(false))
        or_op = axal_binary_op.new(TokenKind::OR, and_op, axal_bool.new(true))
        expected_program.expressions << or_op
        parser = Parser.new(tokens_from_source("logical_operator_ok_3.axal"))

        parser.parse

        # expected: (true and false) or true
        parser.ast.should eq(expected_program)
      end
    end

    context "grouped expressions" do
      it "generates the expected AST for (3 + 4) * 2" do
        expected_program = axal_prog.new
        plus_op = axal_binary_op.new(TokenKind::PLUS, axal_num.new(3.0), axal_num.new(4.0))
        multiplication_op = axal_binary_op.new(TokenKind::ASTERISK, plus_op, axal_num.new(2.0))
        expected_program.expressions << multiplication_op
        parser = Parser.new(tokens_from_source("grouped_expr_ok_1.axal"))

        parser.parse

        parser.ast.should eq(expected_program)
      end

      it "generates the expected AST for ((4 + 4) / 4) * 2" do
        expected_program = axal_prog.new
        plus_op = axal_binary_op.new(TokenKind::PLUS, axal_num.new(4.0), axal_num.new(4.0))
        division_op = axal_binary_op.new(TokenKind::FORWARD_SLASH, plus_op, axal_num.new(4.0))
        multiplication_op = axal_binary_op.new(TokenKind::ASTERISK, division_op, axal_num.new(2.0))
        expected_program.expressions << multiplication_op
        parser = Parser.new(tokens_from_source("grouped_expr_ok_2.axal"))

        parser.parse

        parser.ast.should eq(expected_program)
      end

      it "generates the expected AST for true and (false or true)" do
        expected_program = axal_prog.new
        or_op = axal_binary_op.new(TokenKind::OR, axal_bool.new(false), axal_bool.new(true))
        and_op = axal_binary_op.new(TokenKind::AND, axal_bool.new(true), or_op)
        expected_program.expressions << and_op
        parser = Parser.new(tokens_from_source("grouped_expr_ok_3.axal"))

        parser.parse

        parser.ast.should eq(expected_program)
      end
    end

    context "return" do
      it "generates the expected AST" do
        ret = axal_return.new(axal_num.new(1.0))
        expected_program = axal_prog.new
        expected_program.expressions << ret
        parser = Parser.new(tokens_from_source("return_ok.axal"))

        parser.parse

        parser.ast.should eq(expected_program)
      end
    end

    context "conditionals" do
      it "generates the expected AST for a IF THEN conditional" do
        expected_program = axal_prog.new
        ident = axal_ident.new("world_still_makes_sense")
        var_binding_outer = axal_var_binding.new(ident, axal_bool.new(false))
        eq_op = axal_binary_op.new(TokenKind::DOUBLE_EQUALS, axal_num.new(1.0), axal_num.new(1.0))
        var_binding_inner = axal_var_binding.new(ident, axal_bool.new(true))
        true_block = axal_block.new
        true_block.expressions << var_binding_inner
        conditional = axal_conditional.new(eq_op, true_block)
        expected_program.expressions << var_binding_outer
        expected_program.expressions << conditional
        parser = Parser.new(tokens_from_source("conditional_ok_1.axal"))

        parser.parse

        parser.ast.should eq(expected_program)
      end

      it "does generate the expected AST for a IF THEN ELSE conditional" do
        expected_program = axal_prog.new

        ident_1 = axal_ident.new("world_still_makes_sense")
        ident_2 = axal_ident.new("world_gone_mad")
        var_binding_1 = axal_var_binding.new(ident_1, axal_bool.new(false))
        var_binding_2 = axal_var_binding.new(ident_2, axal_bool.new(false))

        eq_op = axal_binary_op.new(TokenKind::DOUBLE_EQUALS, axal_num.new(1.0), axal_num.new(1.0))
        var_binding_3 = axal_var_binding.new(ident_1, axal_bool.new(true))
        true_block = axal_block.new
        true_block.expressions << var_binding_3

        ineq_op = axal_binary_op.new(TokenKind::NOT_EQUAL, axal_num.new(1.0), axal_num.new(1.0))
        var_binding_4 = axal_var_binding.new(ident_2, axal_bool.new(true))
        false_block = axal_block.new
        false_block.expressions << ineq_op
        false_block.expressions << var_binding_4

        conditional = axal_conditional.new(eq_op, true_block, false_block)

        expected_program.expressions << var_binding_1
        expected_program.expressions << var_binding_2
        expected_program.expressions << conditional
        parser = Parser.new(tokens_from_source("conditional_ok_2.axal"))

        parser.parse

        parser.ast.should eq(expected_program)
      end

      it "does generate the expected AST for a IF THEN ELSE IF conditional" do
        expected_program = axal_prog.new

        ident_1 = axal_ident.new("world_still_makes_sense")
        ident_2 = axal_ident.new("world_gone_mad")
        var_binding_1 = axal_var_binding.new(ident_1, axal_bool.new(false))
        var_binding_2 = axal_var_binding.new(ident_2, axal_bool.new(false))

        eq_op = axal_binary_op.new(TokenKind::DOUBLE_EQUALS, axal_num.new(1.0), axal_num.new(1.0))
        var_binding_3 = axal_var_binding.new(ident_1, axal_bool.new(true))
        true_block = axal_block.new
        true_block.expressions << var_binding_3

        var_binding_4 = axal_var_binding.new(ident_2, axal_bool.new(true))
        true_block_inner = axal_block.new
        true_block_inner.expressions << var_binding_4
        conditional_inner = axal_conditional.new(axal_bool.new(true), true_block_inner)
        false_block = axal_block.new
        false_block.expressions << conditional_inner

        conditional_outer = axal_conditional.new(eq_op, true_block, false_block)

        expected_program.expressions << var_binding_1
        expected_program.expressions << var_binding_2
        expected_program.expressions << conditional_outer
        parser = Parser.new(tokens_from_source("conditional_ok_3.axal"))

        parser.parse

        parser.ast.should eq(expected_program)
      end
    end

    context "repetitions" do
      it "does generate the expected AST for a WHILE loop" do
        expected_program = axal_prog.new
        ident = axal_ident.new("i")
        var_binding_outer = axal_var_binding.new(ident, axal_num.new(0.0))
        lt_op = axal_binary_op.new(TokenKind::LESS_THAN, ident, axal_num.new(10.0))
        fn_call = axal_fn_call.new(axal_ident.new("do_something"), [] of AST::Expression)
        var_binding_inner = axal_var_binding.new(ident, axal_binary_op.new(TokenKind::PLUS, ident, axal_num.new(1.0)))
        repetition_block = axal_block.new
        repetition_block.expressions << fn_call
        repetition_block.expressions << var_binding_inner
        repetition = axal_repetition.new(lt_op, repetition_block)
        expected_program.expressions << var_binding_outer
        expected_program.expressions << repetition
        parser = Parser.new(tokens_from_source("repetition_ok_1.axal"))

        parser.parse

        parser.ast.should eq(expected_program)
      end
    end

    context "module definition" do
      it "generates the expected AST for an empty module" do
        expected_program = axal_prog.new

        mod_def = axal_mod_def.new(axal_ident.new("mymodule"), axal_block.new)

        expected_program.expressions << mod_def
        parser = Parser.new(tokens_from_source("mod_def_ok_1.axal"))

        parser.parse

        parser.ast.should eq(expected_program)
      end

      it "generates the expected AST for a module with a block" do
        expected_program = axal_prog.new

        fn_block = axal_block.new
        fn_block << axal_num.new(1.0)
        fn_name = axal_ident.new("one")
        fn_def = axal_fn_def.new(fn_name, [] of AST::Identifier, fn_block)

        mod_block = axal_block.new
        mod_block << fn_def

        mod_def = axal_mod_def.new(axal_ident.new("mymodule"), mod_block)

        expected_program.expressions << mod_def
        parser = Parser.new(tokens_from_source("mod_def_ok_2.axal"))

        parser.parse

        parser.ast.should eq(expected_program)
      end
    end

    context "qualified function call" do
      it "generates the expected AST for a qualified function call" do
        expected_program = axal_prog.new

        ident = axal_ident.new("go")
        fn_call = axal_fn_call.new(ident, [] of AST::Expression, [axal_ident.new("util")])
        expected_program.expressions << fn_call
        parser = Parser.new(tokens_from_source("mod_call_ok_1.axal"))
        parser.parse

        parser.ast.should eq(expected_program)
      end
    end

    context "function definition" do
      it "generates the expected AST for a function without parameters" do
        expected_program = axal_prog.new

        block_1 = axal_block.new
        block_1 << axal_num.new(1.0)
        ident_1 = axal_ident.new("one")
        fn_def_1 = axal_fn_def.new(ident_1, [] of AST::Identifier, block_1)

        block_2 = axal_block.new
        block_2 << axal_num.new(2.0)
        ident_2 = axal_ident.new("two")
        fn_def_2 = axal_fn_def.new(ident_2, [] of AST::Identifier, block_2)

        expected_program.expressions << fn_def_1
        expected_program.expressions << fn_def_2
        parser = Parser.new(tokens_from_source("fn_def_ok_1.axal"))

        parser.parse

        parser.ast.should eq(expected_program)
      end

      it "generates the expected AST for a function with one parameter" do
        expected_program = axal_prog.new
        fn_name = axal_ident.new("double")
        param = axal_ident.new("num")
        block = axal_block.new
        block << axal_binary_op.new(TokenKind::ASTERISK, param, axal_num.new(2.0))
        fn_def = axal_fn_def.new(fn_name, [param], block)
        expected_program.expressions << fn_def
        parser = Parser.new(tokens_from_source("fn_def_ok_2.axal"))

        parser.parse

        parser.ast.should eq(expected_program)
      end

      it "generates the expected AST for a function with multiple parameters" do
        expected_program = axal_prog.new
        fn_name = axal_ident.new("sum_3")
        param_1 = axal_ident.new("num_1")
        param_2 = axal_ident.new("num_2")
        param_3 = axal_ident.new("num_3")
        plus_op_left = axal_binary_op.new(TokenKind::PLUS, param_1, param_2)
        plus_op_right = axal_binary_op.new(TokenKind::PLUS, plus_op_left, param_3)
        block = axal_block.new
        block << plus_op_right
        fn_def = axal_fn_def.new(fn_name, [param_1, param_2, param_3], block)
        expected_program.expressions << fn_def
        parser = Parser.new(tokens_from_source("fn_def_ok_3.axal"))

        parser.parse

        parser.ast.should eq(expected_program)
      end
    end

    context "function call" do
      it "generates the expected AST for a call with no arguments" do
        expected_program = axal_prog.new
        ident = axal_ident.new("my_func")
        fn_call = axal_fn_call.new(ident, [] of AST::Expression)
        expected_program.expressions << fn_call
        parser = Parser.new(tokens_from_source("fn_call_ok_1.axal"))

        parser.parse

        parser.ast.should eq(expected_program)
      end

      it "generates the expected AST for a call with one argument" do
        expected_program = axal_prog.new
        ident = axal_ident.new("my_func")
        args = [axal_num.new(1.0).as(AST::Expression)]
        fn_call = axal_fn_call.new(ident, args)
        expected_program.expressions << fn_call
        parser = Parser.new(tokens_from_source("fn_call_ok_2.axal"))

        parser.parse

        parser.ast.should eq(expected_program)
      end

      it "generates the expected AST for a call with multiple arguments" do
        expected_program = axal_prog.new
        ident = axal_ident.new("my_func")
        args = [axal_num.new(1.0), axal_ident.new("my_arg"), axal_binary_op.new(TokenKind::PLUS, axal_num.new(2.0), axal_num.new(2.0))]
        fn_call = axal_fn_call.new(ident, args.as(Array(AST::Expression)))
        expected_program.expressions << fn_call
        parser = Parser.new(tokens_from_source("fn_call_ok_3.axal"))

        parser.parse

        parser.ast.should eq(expected_program)
      end
    end

    context "external code" do
      it "produces the expected AST for external code with single line" do
        expected_program = axal_prog.new
        external_code = axal_ext_code.new("1+1")
        expected_program.expressions << external_code

        parser = Parser.new(tokens_from_source("external_code_ok_1.axal"))
        parser.parse

        parser.ast.should eq(expected_program)
      end

      it "produces the expected AST for external code with multi line" do
        expected_program = axal_prog.new
        source = "\nfunction test(a,b,c) { return a + b + c; }\ntest(1,2,3)\n"

        external_code = axal_ext_code.new(source)
        expected_program.expressions << external_code

        parser = Parser.new(tokens_from_source("external_code_ok_2.axal"))
        parser.parse

        parser.ast.should eq(expected_program)
      end
    end

    context "complex programs" do
      it "produces the expected AST for a program that sums all integers between (inclusive) two numbers" do
        expected_program = axal_prog.new
        fn_name = axal_ident.new("sum_integers")
        fn_param_1 = axal_ident.new("first_integer")
        fn_param_2 = axal_ident.new("last_integer")
        fn_body = axal_block.new

        ident_1 = axal_ident.new("i")
        var_binding_1 = axal_var_binding.new(ident_1, fn_param_1)
        ident_2 = axal_ident.new("sum")
        var_binding_2 = axal_var_binding.new(ident_2, axal_num.new(0.0))

        repetition_condition = axal_binary_op.new(TokenKind::LESS_THAN_OR_EQUAL, ident_1, fn_param_2)
        var_binding_3 = axal_var_binding.new(ident_2, axal_binary_op.new(TokenKind::PLUS, ident_2, ident_1))
        var_binding_4 = axal_var_binding.new(ident_1, axal_binary_op.new(TokenKind::PLUS, ident_1, axal_num.new(1.0)))
        repetition_block = axal_block.new
        repetition_block.expressions << var_binding_3
        repetition_block.expressions << var_binding_4
        repetition = axal_repetition.new(repetition_condition, repetition_block)

        println = axal_fn_call.new(axal_ident.new("println"), [ident_2.as(AST::Expression)])

        fn_body.expressions << var_binding_1
        fn_body.expressions << var_binding_2
        fn_body.expressions << repetition
        fn_body.expressions << println
        fn_def = axal_fn_def.new(fn_name, [fn_param_1, fn_param_2], fn_body)
        fn_call = axal_fn_call.new(fn_name, [axal_num.new(1.0).as(AST::Expression), axal_num.new(100.0).as(AST::Expression)])

        expected_program.expressions << fn_def
        expected_program.expressions << fn_call
        parser = Parser.new(tokens_from_source("complex_program_ok_1.axal"))

        parser.parse

        parser.ast.should eq(expected_program)
      end

      it "produces the expected AST for a program that calculates the double of a number" do
        expected_program = axal_prog.new
        fn_name = axal_ident.new("double")
        fn_param_1 = axal_ident.new("num")
        fn_body = axal_block.new
        binary_op = axal_binary_op.new(TokenKind::ASTERISK, fn_param_1, axal_num.new(2.0))
        fn_body.expressions << binary_op
        fn_def = axal_fn_def.new(fn_name, [fn_param_1], fn_body)
        expected_program.expressions << fn_def
        parser = Parser.new(tokens_from_source("complex_program_ok_2.axal"))

        parser.parse

        parser.ast.should eq(expected_program)
      end
    end
  end
end

def tokens_from_source(filename)
  source = File.read("#{__DIR__}/../fixtures/parser/#{filename}")

  Lexer.new(source).start_tokenization
end
