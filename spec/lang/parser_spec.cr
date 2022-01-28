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
  axal_fn_call = AST::FunctionCall

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
  end
end

def tokens_from_source(filename)
  source = File.read("#{__DIR__}/../fixtures/parser/#{filename}")

  Lexer.new(source).start_tokenization
end
