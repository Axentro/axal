module Axal
  struct Location
    getter line : Int32
    getter col : Int32
    getter length : Int32

    def initialize(@line, @col, @length); end

    def ==(other)
      line == other.line &&
        col == other.col &&
        length == other.length
    end
  end
end
