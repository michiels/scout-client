#!/usr/bin/env ruby -wKU

module Scout
  class Command
    class Run < Command
      # for this command, you must call prepare before calling run
      def run
        key = @args.first
        @scout = Scout::Server.new(server, key, history, log)
        @scout.load_history
        @scout.fetch_plan

        if @scout.checkin_now  || @force 
          create_pid_file_or_exit
          @scout.run_plugins_by_plan
          @scout.save_history
        else
          log.info "Not time to checkin yet" if log
        end
      end
    end
  end
end
