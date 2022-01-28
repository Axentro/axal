require "../spec_helper"

describe Lexer do
  describe "parse" do
    context "variable binding" do
      it "generates the expected AST when the syntax is correct" do
        ident = AST::Identifier.new("my_var")
        num = AST::Number.new(1.0)
        var_binding = AST::VarBinding.new(ident, num)
        expected_program = AST::Program.new
        expected_program.expressions << var_binding

        parser = Parser.new(tokens_from_source("var_binding_ok_1.axal"))
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
