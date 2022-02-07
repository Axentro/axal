module Axal
  class Lexer
    WHITESPACE          = [" ", "\r", "\t"]
    ONE_CHAR_LEX        = ["(", ")", ":", ",", ".", "-", "+", "/", "*", "[", "]", "{", "}"]
    ONE_OR_TWO_CHAR_LEX = ["!", "=", ">", "<"]
    KEYWORD             = ["and", "else", "end", "false", "fn", "if", "nil", "or", "return", "true", "while", "mod", "fget"]

    getter source : String
    getter tokens : Array(Token) = [] of Token

    def initialize(@source)
      @line = 0
      @next_p = 0
      @lexeme_start_p = 0
    end

    def start_tokenization
      while source_uncompleted?
        tokenize
      end

      @tokens << Token.new(TokenKind::EOF, "", nil, after_source_end_location)
    end

    def tokenize
      @lexeme_start_p = @next_p
      token = nil

      c = consume

      return if WHITESPACE.includes?(c)
      return ignore_comment_line if c == "#"

      if c == "\n"
        @line += 1
        if @tokens.size > 0
          @tokens << token_from_one_char_lex(c) if tokens.last.kind != "\n"
        end

        return
      end

      token =
        if ONE_CHAR_LEX.includes?(c)
          token_from_one_char_lex(c)
        elsif ONE_OR_TWO_CHAR_LEX.includes?(c)
          token_from_one_or_two_char_lex(c)
        elsif c == %Q{"}
          string
        elsif c == %Q{`}
          external_code
        elsif c == %Q{|}
          triangle
        elsif digit?(c)
          number
        elsif alpha_numeric?(c)
          identifier
        end

      if token
        @tokens << token
      else
        raise("Unknown character #{c}")
      end
    end

    def consume : String
      c = lookahead
      @next_p += 1
      c
    end

    def consume_digits
      while digit?(lookahead)
        consume
      end
    end

    def lookahead(offset = 1) : String
      lookahead_p = (@next_p - 1) + offset
      return "\0" if lookahead_p >= @source.size

      @source[lookahead_p].to_s
    end

    def token_from_one_char_lex(lexeme)
      Token.new(TokenKind.from_single(lexeme), lexeme, nil, current_location)
    end

    def token_from_one_or_two_char_lex(lexeme)
      n = lookahead
      if n == "="
        consume
        Token.new(TokenKind.from_double(lexeme + n), lexeme + n, nil, current_location)
      else
        token_from_one_char_lex(lexeme)
      end
    end

    def ignore_comment_line
      while lookahead != "\n" && source_uncompleted?
        consume
      end
    end

    def string
      while lookahead != %Q{"} && source_uncompleted?
        @line += 1 if lookahead == "\n"
        consume
      end
      raise "Unterminated string error." if source_completed?

      consume # consuming the closing '"'.
      lexeme = @source[(@lexeme_start_p)..(@next_p - 1)].to_s
      # the actual value of the string is the content between the double quotes.
      literal = @source[(@lexeme_start_p + 1)..(@next_p - 2)].to_s

      Token.new(TokenKind::STRING, lexeme, literal, current_location)
    end

    def external_code
      while lookahead != %Q{`} && source_uncompleted?
        @line += 1 if lookahead == "\n"
        consume
      end
      raise "Unterminated string error." if source_completed?

      consume # consuming the closing '`'.
      lexeme = @source[(@lexeme_start_p)..(@next_p - 1)].to_s
      # the actual value of the string is the content between the double quotes.
      literal = @source[(@lexeme_start_p + 1)..(@next_p - 2)].to_s

      Token.new(TokenKind::EXTERNAL_CODE, lexeme, literal, current_location)
    end

    def number
      consume_digits

      # Look for a fractional part.
      if lookahead == "." && digit?(lookahead(2))
        consume # consuming the '.' character.
        consume_digits
      end

      lexeme = @source[@lexeme_start_p..(@next_p - 1)].to_s
      Token.new(TokenKind::NUMBER, lexeme, lexeme.to_f64, current_location)
    end

    def triangle
      if lookahead == ">"
        consume
        Token.new(TokenKind::TRIANGLE, "|>", nil, current_location)
      end
    end

    def identifier
      while alpha_numeric?(lookahead)
        consume
      end

      identifier = @source[@lexeme_start_p..(@next_p - 1)].to_s
      kind =
        if KEYWORD.includes?(identifier)
          TokenKind.from_identifier(identifier)
        else
          TokenKind::IDENTIFIER
        end

      Token.new(kind, identifier, nil, current_location)
    end

    def alpha_numeric?(c : String)
      alpha?(c) || digit?(c)
    end

    def alpha?(c : String)
      c >= "a" && c <= "z" ||
        c >= "A" && c <= "Z" ||
        c == "_"
    end

    def digit?(c : String)
      c >= "0" && c <= "9"
    end

    def source_completed?
      @next_p >= @source.size
    end

    def source_uncompleted?
      !source_completed?
    end

    def current_location
      Location.new(@line, @lexeme_start_p, @next_p - @lexeme_start_p)
    end

    def after_source_end_location
      Location.new(@line, @next_p, 1)
    end
  end
end
