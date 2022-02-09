require "../axal"

require "commander"

cli = Commander::Command.new do |cmd|
  cmd.use = "axal"
  cmd.long = "axal - Axentro automation language for the blockchain"

  #   cmd.flags.add do |flag|
  #     flag.name        = "port"
  #     flag.short       = "-p"
  #     flag.long        = "--port"
  #     flag.default     = 8080
  #     flag.description = "The port to bind to."
  #   end

  #   cmd.flags.add do |flag|
  #     flag.name        = "timeout"
  #     flag.short       = "-t"
  #     flag.long        = "--timeout"
  #     flag.default     = 29.5
  #     flag.description = "The wait time before dropping the connection."
  #   end

  #   cmd.flags.add do |flag|
  #     flag.name        = "verbose"
  #     flag.short       = "-v"
  #     flag.long        = "--verbose"
  #     flag.default     = false
  #     flag.description = "Enable more verbose logging."
  #     flag.persistent  = true
  #   end

  cmd.run do |options, arguments|
    # pp arguments
    # pp options
    # options.string["env"]    # => "development"
    # options.int["port"]      # => 8080
    # options.float["timeout"] # => 29.5
    # options.bool["verbose"]  # => false
    # arguments                # => Array(String)
    pp options
    pp arguments
    puts cmd.help
  end

  cmd.commands.add do |c|
    c.use = "spec <path to spec file or directory>"
    c.short = "Runs specs"
    c.long = cmd.short
    c.run do |options, arguments|
        pp options
      pp arguments # => ["62719"]
    end
  end

  cmd.commands.add do |c|
    c.use = "run <path to axal file or directory>"
    c.short = "Execute axal files"
    c.long = cmd.short
    c.run do |options, arguments|
        pp options
      pp arguments # => ["62719"]
    end
  end
end

Commander.run(cli, ARGV)
