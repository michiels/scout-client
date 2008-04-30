#!/usr/bin/env ruby -wKU

module Scout
  class Command
    class Run < Command
      def run
        key = @args.first
        Scout::Server.new(server, key, history, log) do |scout|
          scout.run_plugins_by_plan
        end
      end
    end
  end
end
