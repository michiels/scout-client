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

      ARGV.options do |opts|
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
        opts.separator "  Clone a client setup:"
        opts.separator "    #{program_name} [OPTIONS] clone " +
                       "CLIENT_KEY NEW_CLIENT_NAME"
        opts.separator ""
        opts.separator "CLIENT_KEY is the indentification key assigned to"
        opts.separator "this client by the server."
        opts.separator ""
        opts.separator "PATH_TO_PLUGIN is the file system path to a Ruby file"
        opts.separator "that contains a Scout plugin."
        opts.separator ""
        opts.separator "PLUGIN_OPTIONS can be the code for a Ruby Hash or the"
        opts.separator "path to a YAML options file containing defaults.  These"
        opts.separator "options will be used for the plugin run."
        opts.separator ""
        opts.separator "NEW_CLIENT_NAME is name you wish to use for the new"
        opts.separator "client the server creates."
        opts.separator ""
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
                 "The level of logging to report." ) do |level|
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

        begin
          opts.parse!
          @usage = opts.to_s
        rescue
          puts opts
          exit
        end
      end
      
      options
    end
    private_class_method :parse_options
    
    def self.dispatch(argv)
      options = parse_options(argv)
      command = if name_or_key = argv.shift
                  if cls = Scout::Command.const_get(name_or_key.capitalize) \
                             rescue nil
                    cls.new(options, argv)
                  else
                    Run.new(options, [name_or_key] + argv)
                  end
                else
                  Install.new(options, argv)
                end
      command.create_pid_file_or_exit.run
    end
    
    def initialize(options, args)
      @server  = options[:server]  || "https://scoutapp.com/"
      @history = options[:history] ||
                 File.join( File.join( (File.expand_path("~") rescue "/"),
                                       ".scout" ),
                            "client_history.yaml" )
      @verbose = options[:verbose] || false
      @level   = options[:level]   || "info"
      
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
            log.error "Unable to unlink pid file:  #{$!.message}"
          end
        end
      rescue
        pid     = File.read(pid_file).strip.to_i rescue "unknown"
        running = true
        begin
          Process.kill(0, pid)
        rescue Errno::ESRCH
          running = false
        rescue
          # do nothing, we didn't have permission to check the running process
        end
        if running
          log.warn "Process #{pid} was already running"
          exit
        else
          log.info "Stale PID file found.  Clearing it and reloading..."
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
