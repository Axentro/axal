require "../spec_helper"

describe Lexer do
  describe "start_tokenization" do
    context "only one character lexemes" do
      it "produces the expected tokens" do
        source = <<-SOURCE
          ( ) . - + / * 
          ! = > <
          \t

          \r
        SOURCE
        expected_tokens = [
          TokenKind::LEFT_PAREN, TokenKind::RIGHT_PAREN, TokenKind::DOT, TokenKind::HYPHEN, TokenKind::PLUS,
          TokenKind::FORWARD_SLASH, TokenKind::ASTERISK,
          TokenKind::NEW_LINE,
          TokenKind::EXCLAMATION, TokenKind::EQUALS, TokenKind::GREATER_THAN, TokenKind::LESS_THAN,
          TokenKind::NEW_LINE, TokenKind::NEW_LINE, TokenKind::NEW_LINE, TokenKind::EOF,
        ]
        lexer = Lexer.new(source)

        lexer.start_tokenization

        lexer.tokens.map(&.kind).should eq(expected_tokens)
      end
    end

    context "only two character lexemes" do
      it "produces the expected tokens" do
        source = <<-SOURCE
        != == >= <=
        \t

        \r
        SOURCE

        expected_tokens = [
          TokenKind::NOT_EQUAL, TokenKind::DOUBLE_EQUALS, TokenKind::GREATER_THAN_OR_EQUAL,
          TokenKind::LESS_THAN_OR_EQUAL, TokenKind::NEW_LINE, TokenKind::NEW_LINE, TokenKind::NEW_LINE,
          TokenKind::EOF,
        ]

        lexer = Lexer.new(source)
        lexer.start_tokenization

        lexer.tokens.map(&.kind).should eq(expected_tokens)
      end
    end

    context "string literals" do
      it "produces the expected token and the expected value" do
        source = <<-SOURCE
          "Hello world."
        SOURCE

        expected_token_types = [TokenKind::STRING, TokenKind::EOF]
        expected_string = Token.new(TokenKind::STRING, %Q{"Hello world."}, "Hello world.", Location.new(0, 2, 14))

        lexer = Lexer.new(source)
        lexer.start_tokenization

        lexer.tokens.map(&.kind).should eq(expected_token_types)
        lexer.tokens.first.should eq(expected_string)
      end
    end
  end

  context "number literals" do
    it "produces the expected token and the expected value" do
      source = <<-SOURCE
        42
        42.42
      SOURCE

      expected_token_types = [TokenKind::NUMBER, TokenKind::NEW_LINE, TokenKind::NUMBER, TokenKind::EOF]
      expected_integer = Token.new(TokenKind::NUMBER, "42", 42.0, Location.new(0, 2, 2))
      expected_float = Token.new(TokenKind::NUMBER, "42.42", 42.42, Location.new(1, 7, 5))

      lexer = Lexer.new(source)
      lexer.start_tokenization

      lexer.tokens.map(&.kind).should eq(expected_token_types)
      lexer.tokens[0].should eq(expected_integer)
      lexer.tokens[2].should eq(expected_float)
    end
  end

  context "identifiers" do
    it "produces the expected tokens" do
      source = <<-SOURCE
        if true
          my_var = 42
        end
      SOURCE

      expected_token_types = [
        TokenKind::IF, TokenKind::TRUE, TokenKind::NEW_LINE,
        TokenKind::IDENTIFIER, TokenKind::EQUALS, TokenKind::NUMBER,
        TokenKind::NEW_LINE, TokenKind::END, TokenKind::EOF,
      ]
      i1 = Token.new(TokenKind::IF, "if", nil, Location.new(0, 2, 2))
      i2 = Token.new(TokenKind::TRUE, "true", nil, Location.new(0, 5, 4))
      i3 = Token.new(TokenKind::IDENTIFIER, "my_var", nil, Location.new(1, 14, 6))
      i4 = Token.new(TokenKind::END, "end", nil, Location.new(2, 28, 3))

      lexer = Lexer.new(source)
      lexer.start_tokenization

      lexer.tokens.map(&.kind).should eq(expected_token_types)
      lexer.tokens[0].should eq(i1)
      lexer.tokens[1].should eq(i2)
      lexer.tokens[3].should eq(i3)
      lexer.tokens[7].should eq(i4)
    end
  end

  context "modules" do
    it "produces the correct tokens" do
      source = <<-SOURCE
        mod mymodule
          fn go
            true
          end
        end
      SOURCE

      lexer = Lexer.new(source)

      expected_token_types = [
        TokenKind::MOD, TokenKind::IDENTIFIER, TokenKind::NEW_LINE, TokenKind::FN,
        TokenKind::IDENTIFIER, TokenKind::NEW_LINE, TokenKind::TRUE, TokenKind::NEW_LINE,
        TokenKind::END, TokenKind::NEW_LINE, TokenKind::END, TokenKind::EOF,
      ]
      lexer.start_tokenization

      lexer.tokens.map(&.kind).should eq(expected_token_types)
    end
  end

  context "when the source is a program with valid lexemes only" do
    it "produces the appropriate tokens" do
      source = <<-SOURCE
        fn sum_integers: first_integer, last_integer
          i = first_integer
          sum = 0
          while i <= last_integer
            sum = sum + i

            i = i + 1
          end

          println(sum)
        end

        sum_integers(1, 100)
      SOURCE

      lexer = Lexer.new(source)

      expected_token_types = [
        TokenKind::FN, TokenKind::IDENTIFIER, TokenKind::COLON, TokenKind::IDENTIFIER, TokenKind::COMMA, TokenKind::IDENTIFIER, TokenKind::NEW_LINE,
        TokenKind::IDENTIFIER, TokenKind::EQUALS, TokenKind::IDENTIFIER, TokenKind::NEW_LINE,
        TokenKind::IDENTIFIER, TokenKind::EQUALS, TokenKind::NUMBER, TokenKind::NEW_LINE,
        TokenKind::WHILE, TokenKind::IDENTIFIER, TokenKind::LESS_THAN_OR_EQUAL, TokenKind::IDENTIFIER, TokenKind::NEW_LINE,
        TokenKind::IDENTIFIER, TokenKind::EQUALS, TokenKind::IDENTIFIER, TokenKind::PLUS, TokenKind::IDENTIFIER, TokenKind::NEW_LINE, TokenKind::NEW_LINE,
        TokenKind::IDENTIFIER, TokenKind::EQUALS, TokenKind::IDENTIFIER, TokenKind::PLUS, TokenKind::NUMBER, TokenKind::NEW_LINE,
        TokenKind::END, TokenKind::NEW_LINE, TokenKind::NEW_LINE,
        TokenKind::IDENTIFIER, TokenKind::LEFT_PAREN, TokenKind::IDENTIFIER, TokenKind::RIGHT_PAREN, TokenKind::NEW_LINE,
        TokenKind::END, TokenKind::NEW_LINE, TokenKind::NEW_LINE,
        TokenKind::IDENTIFIER, TokenKind::LEFT_PAREN, TokenKind::NUMBER, TokenKind::COMMA, TokenKind::NUMBER, TokenKind::RIGHT_PAREN,
        TokenKind::EOF,
      ]

      lexer.start_tokenization

      lexer.tokens.map(&.kind).should eq(expected_token_types)
    end
  end

  context "when the source contains unknown characters" do
    it "raises an error" do
      source = "my_var = 1\n@"
      lexer = Lexer.new(source)

      expect_raises(Exception, "Unknown character @") do
        lexer.start_tokenization
      end
    end
  end
end
