require "../axal"
require "benchmark"
require "colorize"

class SpecRunner
  getter file_or_directory : String

  def initialize(@file_or_directory); end

  def run(internal_test=false)
    total_specs = 0
    total_passed = 0
    total_failed = 0
    failures = [] of Axal::TestResult
    time_taken = Benchmark.measure {
      puts ""
      # also need to check is a axal file
      Dir.glob(@file_or_directory).each do |file|
        result = execute_tests(file)
        result.keys.each do |desc|
          result[desc].each do |test|
            total_specs += 1
            if test.result == true
              total_passed += 1
              print ".".colorize(:green)
            else
              total_failed += 1
              failures << test
              print "F".colorize(:red)
            end
          end
        end
      end
      puts ""
    }
    puts ""
    taken = "Finished in #{time_taken.real}"
    summary = "#{total_specs} specs, #{total_passed} passed, #{total_failed} failed"
    if total_failed > 0
      puts ""
      failures.each do |test|
        puts "'#{test.desc_name}': '#{test.test_name}' expected true but was false".colorize(:red)
      end
      puts ""
      puts taken.colorize(:red)
      puts summary.colorize(:red)
    else
      puts taken.colorize(:green)
      puts summary.colorize(:green)
    end
    internal_test ? total_failed : exit(total_failed)
  end

  private def execute_tests(file)
    core = prepend_core
    source = core += File.read(file)
    lexer = Axal::Lexer.new(source)
    parser = Axal::Parser.new(lexer.start_tokenization)
    parser.parse

    interpreter = Axal::Interpreter.new
    interpreter.interpret(parser.ast)
    interpreter.test_output
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
