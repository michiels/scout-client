#!/usr/bin/env ruby -wKU

require "uri"

module Scout
  class Command
    class Clone < Command
      def run
        key, name = @args
        abort usage if [key, name].any? { |arg| arg.nil? or arg.empty? }
        
        Scout::Server.new(server, key, history, log) do |scout|
          scout.clone_client(
            name,
            "*/30 * * * *  #{user} #{program_path} CLIENT_KEY"
          )
        end
      end
    end
  end
end
