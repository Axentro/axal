module Axal
  struct Token
    getter kind : TokenKind
    getter lexeme : String
    getter literal : Float64? | String?
    getter location : Location

    def initialize(@kind, @lexeme, @literal, @location); end

    def line
      @location.line
    end

    def col
      @location.col
    end

    def length
      @location.length
    end
  end
end
