#!/usr/bin/env ruby -wKU

module Scout
  class Command
    class Run < Command
      def run
        key = @args.first
        # too much external logic of command doing things to server ... should be moved into server class
        @scout = Scout::Server.new(server, key, history, log)
        @scout.load_history
        @scout.fetch_plan


        if @scout.new_plan || @scout.time_to_checkin?  || @force
          if @scout.new_plan
            log.info("Now checking in with new plugin plan") if log
          elsif @scout.time_to_checkin?
            log.info("It is time to checkin") if log
          elsif @force
            log.info("overriding checkin schedule with --force and checking in now.") if log
          end
          create_pid_file_or_exit
          @scout.run_plugins_by_plan
          @scout.save_history
        else
          log.info "Not time to checkin yet. Next checkin in #{@scout.next_checkin}. Override by passing --force to the scout command" if log
        end
      end
    end
  end
end
