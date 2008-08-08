#!/usr/bin/env ruby -wKU

module Scout
  class Plugin
    class << self
      attr_accessor :last_defined

      def inherited(new_plugin)
        @last_defined = new_plugin
      end

      def load(last_run, memory, options)
        new(last_run, memory, options)
      end
      
      # 
      # You can use this method to indicate one or more libraries your plugin
      # requires:
      # 
      #   class MyNeedyPlugin < Scout::Plugin
      #     needs "faster_csv", "elif"
      #     # ...
      #   end
      # 
      # Your build_report() method will not be called if all libraries cannot
      # be loaded.  RubyGems will be loaded if needed to find the libraries.
      # 
      def needs(*libraries)
        if libraries.empty?
          @needs ||= [ ]
        else
          needs.push(*libraries.flatten)
        end
      end
    end

    # Creates a new Scout Plugin to run.
    def initialize(last_run, memory, options)
      @last_run = last_run
      @memory   = memory
      @options  = options
    end
    
    def option(name)
      @options[name] ||
      @options[name.is_a?(String) ? name.to_sym : String(name)]
    end

    # Builds the data to send to the server.
    #
    # We programatically define several helper methods for creating this data.
    # 
    # Usage:
    # 
    #   reports << {:data => "here"}
    #   report(:data => "here")
    #   add_report(:data => "here")
    # 
    #   alerts << {:subject => "subject", :body => "body"}
    #   alert("subject", "body")
    #   alert(:subject => "subject", :body => "body")
    #   add_alert("subject", "body")
    #   add_alert(:subject => "subject", :body => "body")
    # 
    #   errors << {:subject => "subject", :body => "body"}
    #   error("subject", "body")
    #   error(:subject => "subject", :body => "body")
    #   add_error("subject", "body")
    #   add_error(:subject => "subject", :body => "body")
    #     
    def data_for_server
      @data_for_server ||= { :reports => [ ],
                             :alerts  => [ ],
                             :errors  => [ ],
                             :memory  => { } }
    end
    
    %w[report alert error].each do |kind|
      class_eval <<-END
        def #{kind}s
          data_for_server[:#{kind}s]
        end
        
        if "#{kind}" == "report"
          def report(new_entry)
            reports << new_entry
          end
        else
          def #{kind}(*fields)
            #{kind}s << ( fields.first.is_a?(Hash) ?
                          fields.first :
                          {:subject => fields.first, :body => fields.last} )
          end
        end
        alias_method :add_#{kind}, :#{kind}
      END
    end
    
    #
    # Usage:
    # 
    #   memory(:no_track)
    #   memory.delete(:no_track)
    #   memory.clear
    # 
    def memory(name = nil)
      if name.nil?
        data_for_server[:memory]
      else
        @memory[name] ||
        @memory[name.is_a?(String) ? name.to_sym : String(name)]
      end
    end
    
    #
    # Usage:
    # 
    #   remember(:name, value)
    #   remember(:name1, value1, :name2, value2)
    #   remember(:name => value)
    #   remember(:name1 => value1, :name2 => value2)
    #   remember(:name1, value1, :name2 => value2)
    # 
    def remember(*args)
      hashes, other = args.partition { |value| value.is_a? Hash }
      hashes.each { |hash| memory.merge!(hash) }
      (0...other.size).step(2) { |i| memory.merge!(other[i] => other[i + 1]) }
    end
    
    #
    # Old plugins will work because they override this method.  New plugins can
    # now leave this method in place, add a build_report() method instead, and
    # use the new helper methods to build up content inside which will
    # automatically be returned as the end result of the run.
    # 
    def run
      build_report if self.class.needs.all? { |l| library_available?(l) }
      data_for_server
    end
    
    private
    
    #
    # Returns true is a library can be loaded.  A bare require is made as the
    # first attempt.  If that fails, RubyGems is loaded and another attempt is
    # made.  If the library cannot be loaded either way, an error() is generated
    # and build_report() will not be called.
    # 
    def library_available?(library)
      begin
        require library
      rescue LoadError
        begin
          require "rubygems"
          require library
        rescue LoadError
          error("Failed to load library", "Could not load #{library}")
          return false
        end
      end
      true
    end
  end
end
