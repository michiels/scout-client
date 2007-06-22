#!/usr/bin/env ruby -wKU

module SSpy
  class Plugin
    class << self
      attr_reader :last_defined

      def inherited(new_plugin)
        @last_defined = new_plugin
      end

      def load(last_run, options)
        new(last_run, options)
      end
    end

    def initialize(last_run, options)
      @last_run = last_run
      @options  = options
    end
  end
end
