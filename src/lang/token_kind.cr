module Axal
  enum TokenKind
    TAB             =   9
    NEW_LINE        =  10
    CARRIAGE_RETURN =  13
    SPACE           =  32
    EXCLAMATION     =  33
    DOUBLE_QUOTE    =  34
    HASH            =  35
    DOLLAR          =  36
    PERCENT         =  37
    AMPERSAND       =  38
    SINGLE_QUOTE    =  39
    LEFT_PAREN      =  40
    RIGHT_PAREN     =  41
    ASTERISK        =  42
    PLUS            =  43
    COMMA           =  44
    HYPHEN          =  45
    DOT             =  46
    FORWARD_SLASH   =  47
    ZERO            =  48
    ONE             =  49
    TWO             =  50
    THREE           =  51
    FOUR            =  52
    FIVE            =  53
    SIX             =  54
    SEVEN           =  55
    EIGHT           =  56
    NINE            =  57
    COLON           =  58
    SEMI_COLOM      =  59
    LESS_THAN       =  60
    EQUALS          =  61
    GREATER_THAN    =  62
    QUESTION        =  63
    AT              =  64
    UPPER_A         =  65
    UPPER_B         =  66
    UPPER_C         =  67
    UPPER_D         =  68
    UPPER_E         =  69
    UPPER_F         =  70
    UPPER_G         =  71
    UPPER_H         =  72
    UPPER_I         =  73
    UPPER_J         =  74
    UPPER_K         =  75
    UPPER_L         =  76
    UPPER_M         =  77
    UPPER_N         =  78
    UPPER_O         =  79
    UPPER_P         =  80
    UPPER_Q         =  81
    UPPER_R         =  82
    UPPER_S         =  83
    UPPER_T         =  84
    UPPER_U         =  85
    UPPER_V         =  86
    UPPER_W         =  87
    UPPER_X         =  88
    UPPER_Y         =  89
    UPPER_Z         =  90
    LEFT_BRACKET    =  91
    BACK_SLASH      =  92
    RIGHT_BRACKET   =  93
    CIRCUMFLEX      =  94
    LOW_LINE        =  95
    BACK_TICK       =  96
    LOWER_A         =  97
    LOWER_B         =  98
    LOWER_C         =  99
    LOWER_D         = 100
    LOWER_E         = 101
    LOWER_F         = 102
    LOWER_G         = 103
    LOWER_H         = 104
    LOWER_I         = 105
    LOWER_J         = 106
    LOWER_K         = 107
    LOWER_L         = 108
    LOWER_M         = 109
    LOWER_N         = 110
    LOWER_O         = 111
    LOWER_P         = 112
    LOWER_Q         = 113
    LOWER_R         = 114
    LOWER_S         = 115
    LOWER_T         = 116
    LOWER_U         = 117
    LOWER_V         = 118
    LOWER_W         = 119
    LOWER_X         = 120
    LOWER_Y         = 121
    LOWER_Z         = 122
    LEFT_CURLY      = 123
    BAR             = 124
    RIGHT_CURLY     = 125
    TILDE           = 126

    DOUBLE_EQUALS
    NOT_EQUAL
    GREATER_THAN_OR_EQUAL
    LESS_THAN_OR_EQUAL

    STRING
    NUMBER
    IDENTIFIER

    AND
    ELSE
    END
    FALSE
    FN
    MOD
    IF
    NIL
    OR
    RETURN
    TRUE
    WHILE

    EOF
    UNKNOWN

    def self.from_single(value) : TokenKind
      TokenKind.from_value(value.codepoint_at(0))
    rescue e : Exception
      puts "Unknown Latin Ascii character: #{value.inspect} (codepoint: #{value.codepoints})"
      UNKNOWN
    end

    def self.from_identifier(value) : TokenKind
      case value
      when "and"
        AND
      when "else"
        ELSE
      when "end"
        END
      when "false"
        FALSE
      when "fn"
        FN
      when "if"
        IF
      when "nil"
        NIL
      when "or"
        OR
      when "return"
        RETURN
      when "true"
        TRUE
      when "while"
        WHILE
      when "mod"
        MOD
      else
        IDENTIFIER
      end
    end

    def self.from_double(value) : TokenKind
      case value
      when "=="
        DOUBLE_EQUALS
      when "!="
        NOT_EQUAL
      when ">="
        GREATER_THAN_OR_EQUAL
      when "<="
        LESS_THAN_OR_EQUAL
      else
        UNKNOWN
      end
    end

    def self.letters
      [
        UPPER_A,
        UPPER_B,
        UPPER_C,
        UPPER_D,
        UPPER_E,
        UPPER_F,
        UPPER_G,
        UPPER_H,
        UPPER_I,
        UPPER_J,
        UPPER_K,
        UPPER_L,
        UPPER_M,
        UPPER_N,
        UPPER_O,
        UPPER_P,
        UPPER_Q,
        UPPER_R,
        UPPER_S,
        UPPER_T,
        UPPER_U,
        UPPER_V,
        UPPER_W,
        UPPER_X,
        UPPER_Y,
        UPPER_Z,
        LOWER_A,
        LOWER_B,
        LOWER_C,
        LOWER_D,
        LOWER_E,
        LOWER_F,
        LOWER_G,
        LOWER_H,
        LOWER_I,
        LOWER_J,
        LOWER_K,
        LOWER_L,
        LOWER_M,
        LOWER_N,
        LOWER_O,
        LOWER_P,
        LOWER_Q,
        LOWER_R,
        LOWER_S,
        LOWER_T,
        LOWER_U,
        LOWER_V,
        LOWER_W,
        LOWER_X,
        LOWER_Y,
        LOWER_Z,
      ]
    end

    def self.numbers
      [
        ZERO,
        ONE,
        TWO,
        THREE,
        FOUR,
        FIVE,
        SIX,
        SEVEN,
        EIGHT,
        NINE,
      ]
    end
  end
end
