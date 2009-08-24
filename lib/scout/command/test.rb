#!/usr/bin/env ruby -wKU

require "pp"

module Scout
  class Command
    class Test < Command
      def run
        plugin, options = @args
        
        # read the plugin_code from the file specified
        plugin_code    = File.read(plugin)
        plugin_options = if options.to_s[0, 1] == "{"
          eval(options)  # options from command-line
        elsif options
          # 
          # read the plugin_options from the YAML file specified,
          # parse each option and use the default value specified
          # in the options as the value to be passed to the test plugin
          # 
          Hash[ *File.open(options) { |f| YAML.load(f) }["options"].
                 map { |name, details| [name, details["default"]] }.flatten ]
        else
          Hash.new
        end

        Scout::Server.new(nil, nil, history, log) do |scout|
          scout.prepare_checkin
          scout.process_plugin( 'interval'  => 0,
                                'plugin_id' => 1,
                                'name'      => "Local Plugin",
                                'code'      => plugin_code,
                                'options'   => plugin_options,
                                'path'      => plugin )
          scout.show_checkin(:pp)
        end  
      end
    end
  end
end
