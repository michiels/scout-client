#!/usr/bin/env ruby -wKU

module Scout
  class Command
    class Install < Command
      def run
        create_pid_file_or_exit

        abort usage unless $stdin.tty?
        
        puts <<-END_INTRO.gsub(/^ {8}/, "")
        === Scout Installation Wizard ===

        You need the Server Key displayed in the Server Settings tab.
        It looks like:

          6ecad322-0d17-4cb8-9b2c-a12c4541853f

        Enter the Server Key:
        END_INTRO
        key = gets.to_s.strip

        puts "\nAttempting to contact the server..."
        begin
          Scout::Server.new(server, key, history, log) { |scout| scout.fetch_plan }

          puts <<-END_SUCCESS.gsub(/^ {10}/, "")
          Success!

          Now, you must setup Scout to run on a scheduled basis.

          If you are using the system crontab
          (usually located at /etc/crontab):

          ****** START CRONTAB SAMPLE ******
          * * * * *  #{user} #{program_path} #{key}
          ******  END CRONTAB SAMPLE  ******

          If you are using this current user's crontab
          (using crontab -e to edit):

          ****** START CRONTAB SAMPLE ******
          * * * * *  #{program_path} #{key}
          ******  END CRONTAB SAMPLE  ******

          For help setting up Scout with crontab, please visit:

            http://scoutapp.com/help#cron

          END_SUCCESS
        rescue SystemExit
          puts $!.message
          puts <<-END_ERROR.gsub(/^ {10}/, "")

          Failed. 
          For more help, please visit:

          http://scoutapp.com/help

          END_ERROR
        end
      end
    end
  end
end
