require "../axal"
require "colorize"

class SourceRunner
  getter file : String

  def initialize(@file); end

  def run
    # also need to check is a axal file
    source = Dir.glob(@file)
    if source.size > 0
      execute_source(file)
    end
  end

  private def execute_source(file)
    core = prepend_core
    source = core += File.read(file)
    lexer = Axal::Lexer.new(source)
    parser = Axal::Parser.new(lexer.start_tokenization)
    parser.parse

    interpreter = Axal::Interpreter.new
    interpreter.interpret(parser.ast)
  end

  private def prepend_core
    content = ""
    ["array", "object"].each do |file|
      content += "\n"
      content += FileStorage.get("src/#{file}.axal").gets_to_end
      content += "\n"
    end    
    content
  end
end
