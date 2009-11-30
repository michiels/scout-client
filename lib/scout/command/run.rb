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

        # BEGIN: Experimental -- may not keep this.
        # Potential problems: increases complexity, messes with the history file outside a lock.
        if @scout.directives['reset_history']
          File.delete(history)
          @server.create_blank_history
        end
        # END: Experimental -- may not keep this

        if @scout.checkin_now  || @force
          if log
            log.info(@scout.checkin_now ? "It is time to checkin" : "overriding checkin time with --force and checking in now.")  
          end
          create_pid_file_or_exit
          @scout.run_plugins_by_plan
          @scout.save_history
        else
          log.info "Not time to checkin yet. Override by passing --force to the scout command" if log
        end
      end
    end
  end
end
