require "../axal"
require "../cli/spec_runner"
require "../cli/source_runner"

require "commander"

cli = Commander::Command.new do |cmd|
  cmd.use = "axal"
  cmd.long = "axal - Axentro automation language for the blockchain"

  cmd.run do
    puts cmd.help
  end

  cmd.commands.add do |c|
    c.use = "spec <path to spec files e.g spec/*>"
    c.short = "Runs specs"
    c.long = cmd.short
    c.run do |_, arguments|
      if arguments.size > 0
        SpecRunner.new(arguments.first).run
      else
        SpecRunner.new("spec/*").run
      end
    end
  end

  cmd.commands.add do |c|
    c.use = "run <path to axal file>"
    c.short = "Execute axal file"
    c.long = cmd.short
    c.run do |_, arguments|
      if arguments.size > 0
        SourceRunner.new(arguments.first).run
      else
        puts "Please supply a path to an axal source file e.g. src/file.axal"
      end
    end
  end
end

Commander.run(cli, ARGV)
