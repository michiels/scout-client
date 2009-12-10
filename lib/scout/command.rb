#!/usr/bin/env ruby -wKU

require "optparse"
require "logger"
require "fileutils"

module Scout
  class Command
    def self.user
      @user ||= ENV["USER"] || ENV["USERNAME"] || "root"
    end

    def self.program_name
      @program_name ||= File.basename($PROGRAM_NAME)
    end

    def self.program_path
      @program_path ||= File.expand_path($PROGRAM_NAME)
    end

    def self.usage
      @usage
    end

    def self.parse_options(argv)
      options = { }

      op = OptionParser.new do |opts|
        opts.banner = "Usage:"

        opts.separator "  Normal checkin with server:"
        opts.separator "    #{program_name} [OPTIONS] CLIENT_KEY"
        opts.separator "    ... OR ..."
        opts.separator "    #{program_name} [OPTIONS] run CLIENT_KEY"
        opts.separator "  Install:"
        opts.separator "    #{program_name}"
        opts.separator "    ... OR ..."
        opts.separator "    #{program_name} [OPTIONS] install"
        opts.separator "  Local plugin testing:"
        opts.separator "    #{program_name} [OPTIONS] test " +
                       "PATH_TO_PLUGIN [PLUGIN_OPTIONS]"
        opts.separator "[PLUGIN_OPTIONS] format: opt1=val1 opt2=val2 opt2=val3 etc."
        opts.separator "Plugin will use internal defaults if options aren't provided."
        opts.separator " "
        opts.separator "Note: This client is meant to be installed and"
        opts.separator "invoked through cron or any other scheduler."
        opts.separator ""
        opts.separator "Specific Options:"

        opts.on( "-s", "--server SERVER", String,
                 "The URL for the server to report to." ) do |url|
          options[:server] = url
        end

        opts.separator ""

        opts.on( "-d", "--data DATA", String,
                 "The data file used to track history." ) do |file|
          options[:history] = file
        end
        opts.on( "-l", "--level LEVEL",
                 Logger::SEV_LABEL.map { |l| l.downcase },
                 "The level of logging to report. Use -ldebug for most detail." ) do |level|
          options[:level] = level
        end

        opts.separator "Common Options:"

        opts.on( "-h", "--help",
                 "Show this message." ) do
          puts opts
          exit
        end
        opts.on( "-v", "--[no-]verbose",
                 "Turn on logging to STDOUT" ) do |bool|
          options[:verbose] = bool
        end

        opts.on( "-V", "--version",
                 "Display the current version") do |version|
          puts Scout::VERSION
          exit
        end

        opts.on( "-F", "--force", "Force checkin to Scout server regardless of last checkin time") do |bool|
          options[:force] = bool
        end

        opts.separator " "
        opts.separator "Examples: "
        opts.separator "1. Normal run (example key; use your own key):"
        opts.separator "     scout 6ecad322-0d17-4cb8-9b2c-a12c4541853f"
        opts.separator "2. Normal run with logging to standard out (example key; use your own key):"
        opts.separator "     scout  --verbose 6ecad322-0d17-4cb8-9b2c-a12c4541853f"
        opts.separator "3. Test a plugin:"
        opts.separator "     scout test my_plugin.rb foo=18 bar=42"

      end

      begin
        op.parse!(argv)
        @usage = op.to_s
      rescue
        puts op
        exit
      end
      options
    end
    private_class_method :parse_options

    def self.dispatch(argv)
      # capture help command
      argv.push("--help") if argv.first == 'help'
      options = parse_options(argv)
      command = if name_or_key = argv.shift
                  if cls = (Scout::Command.const_get(name_or_key.capitalize) rescue nil)
                    cls.new(options, argv)
                  else
                    Run.new(options, [name_or_key] + argv)
                  end
                else
                  Install.new(options, argv)
                end
      command.run
    end

    def initialize(options, args)
      @server  = options[:server]  || "https://scoutapp.com/"
      @history = options[:history] ||
                 File.join( File.join( (File.expand_path("~") rescue "/"),
                                       ".scout" ),
                            "client_history.yaml" )
      @verbose = options[:verbose] || false
      @level   = options[:level]   || "info"
      @force   = options[:force]   || false

      @args    = args
    end

    attr_reader :server, :history

    def config_dir
      return @config_dir if defined? @config_dir
      @config_dir = File.dirname(history)
      FileUtils.mkdir_p(@config_dir) # ensure dir exists
      @config_dir
    end

    def verbose?
      @verbose
    end

    def log
      return @log if defined? @log
      @log = if verbose?
               log                 = Logger.new($stdout)
               log.datetime_format = "%Y-%m-%d %H:%M:%S "
               log.level           = level
               log
             else
               nil
             end
    end

    def level
      Logger.const_get(@level.upcase) rescue Logger::INFO
    end

    def user
      @user ||= Command.user
    end

    def program_name
      @program_name ||= Command.program_name
    end

    def program_path
      @program_path ||= Command.program_path
    end

    def usage
      @usage ||= Command.usage
    end

    def create_pid_file_or_exit
      pid_file = File.join(config_dir, "scout_client_pid.txt")
      begin
        File.open(pid_file, File::CREAT|File::EXCL|File::WRONLY) do |pid|
          pid.puts $$
        end
        at_exit do
          begin
            File.unlink(pid_file)
          rescue
            log.error "Unable to unlink pid file:  #{$!.message}" if log
          end
        end
      rescue
        pid     = File.read(pid_file).strip.to_i rescue "unknown"
        running = true
        begin
          Process.kill(0, pid)
          if stat = File.stat(pid_file)
            if mtime = stat.mtime
              if Time.now - mtime > 25 * 60  # assume process is hung after 25m
                log.info "Trying to KILL an old process..." if log
                Process.kill("KILL", pid)
                running = false
              end
            end
          end
        rescue Errno::ESRCH
          running = false
        rescue
          # do nothing, we didn't have permission to check the running process
        end
        if running
          if pid == "unknown"
            log.warn "Could not create or read PID file.  "                +
                     "You may need to the path to the config directory.  " +
                     "See:  http://scoutapp.com/help#data_file" if log
          else
            log.warn "Process #{pid} was already running" if log
          end
          exit
        else
          log.info "Stale PID file found.  Clearing it and reloading..." if log
          File.unlink(pid_file) rescue nil
          retry
        end
      end

      self
    end
  end
end

# dynamically load all available commands
Dir.glob(File.join(File.dirname(__FILE__), *%w[command *.rb])) do |command|
  require command
end
