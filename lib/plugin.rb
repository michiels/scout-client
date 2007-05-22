#!/usr/bin/env ruby -wKU

class Plugin
  Info = Struct.new(:name, :version, :code)
  
  class << self
    def last_defined
      @last_loaded
    end
    
    def inherited(new_plugin)
      @last_loaded = new_plugin
    end
    
    def load
      new
    end
  end
end