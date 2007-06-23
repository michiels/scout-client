#!/usr/bin/env ruby -wKU

require "net/http"
require "uri"
require "yaml"
require "timeout"

module SSpy
  class Server
    URLS = { :plan   => "/clients/CLIENT_KEY/plugins.spy",
             :report => "/clients/CLIENT_KEY/plugins/PLUGIN_ID/reports.spy",
             :error  => "/clients/CLIENT_KEY/plugins/PLUGIN_ID/errors.spy",
             :alert  => "/clients/CLIENT_KEY/plugins/PLUGIN_ID/alerts.spy" }

    def initialize(server, client_key, history_file, logger = nil)
      @server       = server
      @client_key   = client_key
      @history_file = history_file
      @history      = Hash.new
      @logger       = logger
      
      if block_given?
        load_history
        yield self
        save_history
      end
    end
    
    def load_history
      unless File.exist? @history_file
        debug "Creating empty history file..."
        File.open(@history_file, "w") do |file|
          YAML.dump({"last_runs" => Hash.new}, file)
        end
        info "History file created."
      end
      debug "Loading history file..."
      @history = File.open(@history_file) { |file| YAML.load(file) }
      info "History file loaded."
    end
    
    def save_history
      debug "Saving history file..."
      File.open(@history_file, "w") { |file| YAML.dump(@history, file) }
      info "History file saved."
    end
    
    def run_plugins_by_plan
      plan do |plugin|
        info "Processing the #{plugin[:name]} plugin:"
        last_run = @history["last_runs"][plugin[:name]]
        run_time = Time.now
        if last_run.nil? or run_time > last_run + plugin[:interval]
          debug "Plugin is past interval and needs to be run.  " +
                "(last run:  #{last_run || 'nil'})"
          debug "Compiling plugin..."
          begin
            eval(plugin[:code])
            info "Plugin compiled."
          rescue Exception
            fatal "Plugin would not compile."
            exit
          end
          debug "Loading plugin..."
          if job = Plugin.last_defined.load( last_run, 
                                             plugin[:options] || Hash.new )
            info "Plugin loaded."
            debug "Running plugin..."
            begin
              data = nil
              Timeout.timeout(5) { data = job.run }
            rescue Timeout::Error
              fatal "Plugin took too long to run."
              exit
            end
            info "Plugin completed its run."
            report(data[:report], plan[:plugin_id]) if data[:report]
            if data[:alerts] and not data[:alerts].empty?
              data[:alerts].each { |a| alert(a, plan[:plugin_id]) }
            end
            error(data[:error], plan[:plugin_id]) if data[:error]
            @history["last_runs"][plugin[:name]] = run_time
          else
            error({:subject => "Plugin would not load."}, plan[:plugin_id])
          end
        else
          debug "Plugin does not need to be run at this time.  " +
                "(last run:  #{last_run || 'nil'})"
        end
        info "Plugin #{plugin[:name]} processing complete."
      end
    end
    
    def plan
      url = urlify(:plan)
      info "Loading plan from #{url}..."
      get(url, "Could not retrieve plan from server.") do |res|
        begin
          plan = Marshal.load(res.body)
          info "Plan loaded.  (#{plan.size} plugins:  " +
               "#{plan.map { |p| p[:name] }.join(', ')})"
        rescue TypeError
          fatal "Plan from server was malformed."
          exit
        end
        plan.each do |plugin|
          begin
            yield plugin
          rescue RuntimeError
            error( { :subject => "Exception:  #{$!.message}.",
                     :body    => $!.backtrace },
                   plugin[:plugin_id] )
          end
        end
      end
    end

    def report(data, plugin_id)
      url = urlify(:report, :plugin_id => plugin_id)
      debug "Sending report to #{url} (#{data.inspect})..."
      post url,
           "Unable to send report to server.",
           :report => {:data => data, :plugin_id => plugin_id}
      info "Report sent."
    end

    def alert(data, plugin_id)
      url = urlify(:alert, :plugin_id => plugin_id)
      debug "Sending alert to #{url} (subject: #{data[:subject]})..."
      post url,
           "Unable to send alert to server.",
           :alert => data.merge(:plugin_id => plugin_id)
      info "Alert sent."
    end

    def error(data, plugin_id)
      url = urlify(:error, :plugin_id => plugin_id)
      debug "Sending error to #{url} (subject: #{data[:subject]})..."
      post url,
           "Unable to log error on server.",
            :error => data.merge(:plugin_id => plugin_id)
      info "Error sent."
    end
    
    private

    def urlify(url_name, options = Hash.new)
      URI.join( @server,
                URLS[url_name].
                  gsub(/\bCLIENT_KEY\b/, @client_key).
                  gsub(/\b[A-Z_]+\b/) { |k| options[k.downcase.to_sym] || k } )
    end

    def paramify(params, prefix = nil)
      params.inject(Hash.new) do |all, (key, value)|
        parent = prefix ? "#{prefix}[#{key}]" : String(key)
        if value.is_a? Hash
          all.merge(paramify(value, parent))
        else
          all.merge(parent => String(value))
        end
      end
    end
    
    def post(url, error, params = {}, &response_handler)
      request(response_handler, error) do
        Net::HTTP.post_form(url, paramify(params))
      end
    end

    def get(url, error, params = {}, &response_handler)
      request(response_handler, error) do
        Net::HTTP.start(url.host, url.port) { |http| http.get(url.path) }
      end
    end
    
    def request(response_handler, error)
      response = yield
      case response
      when Net::HTTPSuccess
        response_handler[response] unless response_handler.nil?
      else
        abort error
      end
    rescue Timeout::Error
      abort "Request timed out."
    end
    
    # Forward Logger methods to an active instance, when there is one.
    def method_missing(meth, *args, &block)
      if (Logger::SEV_LABEL - %w[ANY]).include? meth.to_s.upcase
        @logger.send(meth, *args, &block) unless @logger.nil?
      else
        super
      end
    end
  end
end
