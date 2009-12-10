#!/usr/bin/env ruby -wKU

require "pp"

module Scout
  class Command
    class Test < Command
      def run
        create_pid_file_or_exit
        plugin, *provided_options = @args
        # read the plugin_code from the file specified
        plugin_code    = File.read(plugin)

        options_for_run = {}

        # deal with embedded options yaml
        if  options_yaml = Scout::Plugin.extract_options_yaml_from_code(plugin_code)
          options=Scout::PluginOptions.from_yaml(options_yaml)

          if options.error
            puts "Problem parsing option definition in the plugin code (ignoring and continuing):"
            puts options_yaml
          else
            puts "== Plugin options: "
            puts options.to_s
            options.select{|o|o.has_default?}.each{|o|options_for_run[o.name]=o.default}
          end
        else
          puts "== This plugin doesn't have option metadata."
        end

        # provided_options are what the user gave us in the command line. Here, we merge them into
        # the defaults we've already established (if any) for this run.
        provided_options.each do |e|
          if e.include?('=')
            k,v=e.split('=',2)
            options_for_run[k]=v
          else
            puts "ERROR: Option '#{e}' is no good -- provided options should be in the format name=value."
          end
        end
        if options_for_run.any?
          puts "== Running plugin with: #{options_for_run.to_a.map{|a| "#{a.first}=#{a.last}"}.join('; ') }"
        else
          puts "== You haven't provided any options for running this plugin."
        end

        Scout::Server.new(nil, nil, history, log) do |scout|
          scout.prepare_checkin
          scout.process_plugin( 'interval'  => 0,
                                'plugin_id' => 1,
                                'name'      => "Local Plugin",
                                'code'      => plugin_code,
                                'options'   => options_for_run,
                                'path'      => plugin )
          puts "== Output:"
          scout.show_checkin(:pp)
        end  
      end
    end
  end
end
