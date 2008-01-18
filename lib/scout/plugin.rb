#!/usr/bin/env ruby -wKU

module Scout
  class Plugin
    class << self
      attr_reader :last_defined

      def inherited(new_plugin)
        @last_defined = new_plugin
      end

      def load(last_run, memory, options)
        new(last_run, memory, options)
      end
    end

    # Creates a new Scout Plugin to run.
    # 
    def initialize(last_run, memory, options)
      @last_run = last_run
      @memory   = memory
      @options  = options
    end
  end
end
