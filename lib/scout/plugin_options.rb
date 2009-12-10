#!/usr/bin/env ruby -wKU

require 'yaml'

module Scout
  # a data structure of an individual plugin option
  class PluginOption
    attr_reader :name, :notes, :default, :advanced, :password, :required
    def initialize(name, h)
      @name=name
      @notes=h['notes'] || ''
      @default=h['default'] || ''
      @attributes=h['attributes'] || ''
      @advanced = @attributes.include?('advanced')
      @password = @attributes.include?('password')
      @required = @attributes.include?('required')
    end

    # convenience -- for nicer syntax
    def advanced?; @advanced; end
    def password?; @password; end
    def required?; @required; end
    def has_default?; default != '';end

    def to_s
      required_string = required? ? " (required). " : ""
      default_string = default == '' ? '' : " Default: #{default}. " 
      "'#{name}'#{required_string}#{default_string}#{notes}"
    end
  end

  # A collection of pluginOption
  # Create: opts=PluginOptions.from_yaml(yaml_string)
  # Check if there were any problems -- opts.error -- should be nil.
  #
  # A valid options yaml looks like this:
  #    max_swap_used:
  #      notes: If swap is larger than this amount, an alert is generated. Amount should be in MB.
  #      default: 2048  # 2 GB
  #    max_swap_ratio:
  #      notes: If swap used over memory used is larger than this amount, an alert is generated
  #      default: 3
  #      attributes: required advanced
  class PluginOptions < Array

    attr_accessor :error

    # Should be valid YAML, a hash of hashes ... if not, will be caught in the rescue below
    def self.from_yaml(string)
      options_array=[]
      error=nil

      items=YAML.load(string)
      items.each_pair {|name, hash| options_array.push(PluginOption.new(name,hash)) }
    rescue
      error="Invalid Plugin Options"
    ensure
      res=PluginOptions.new(options_array)
      res.error=error
      return res
    end

    def advanced
      select{|o|o.advanced? }
    end

    def regular
      select{|o|!o.advanced? }
    end

    def to_s
      res=[]
      each_with_index do |opt,i|
        res.push "#{i+1}. #{opt.to_s}"
      end
      res.join("\n")
    end

  end
end
