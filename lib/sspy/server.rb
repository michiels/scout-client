#!/usr/bin/env ruby -wKU

require "net/http"
require "uri"
require "yaml"

module SSpy
  class Server
    URLS = { :plan   => "/clients/CLIENT_KEY/plugins.spy",
             :report => "/clients/CLIENT_KEY/plugins/PLUGIN_ID/reports.spy",
             :error  => "/clients/CLIENT_KEY/plugins/PLUGIN_ID/errors.spy",
             :alert  => "/clients/CLIENT_KEY/plugins/PLUGIN_ID/alerts.spy" }

    def initialize(server, client_key, history_file)
      @server       = server
      @client_key   = client_key
      @history_file = history_file
      @history      = Hash.new
      
      if block_given?
        load_history
        yield self
        save_history
      end
    end
    
    def load_history
      unless File.exist? @history_file
        File.open(@history_file, "w") do |file|
          YAML.dump({"last_runs" => Hash.new}, file)
        end
      end
      @history = File.open(@history_file) { |file| YAML.load(file) }
    end
    
    def save_history
      File.open(@history_file, "w") { |file| YAML.dump(@history, file) }
    end
    
    def run_plugins_by_plan
      plan do |plugin|
        last_run = ["last_runs"][plugin[:name]]
        run_time = Time.now
        if last_run.nil? or run_time > last_run + plugin[:interval]
          eval(plugin[:code])
          if job = Plugin.last_defined.load( last_run, 
                                             plugin[:options] || Hash.new )
            data = job.run
            report(data[:report], plan[:plugin_id]) if data[:report]
            if data[:alerts] and not data[:alerts].empty?
              data[:alerts].each { |a| alert(a, plan[:plugin_id]) }
            end
            error(data[:error], plan[:plugin_id]) if data[:error]
            @history["last_runs"][plugin[:name]] = run_time
          else
            error({:subject => "Plugin would not load."}, plan[:plugin_id])
          end
        end
      end
    end
    
    def plan
      get(:plan, "Could not retrieve plan from server.") do |res|
        begin
          plan = Marshal.load(res.body)
        rescue TypeError
          abort "Plan from server was malformed."
        end
        plan.each do |plugin|
          begin
            yield plugin
          rescue Exception
            error( { :subject => "Exception:  #{$!.message}.",
                     :body    => $!.backtrace },
                   plugin[:plugin_id] )
          end
        end
      end
    end

    def report(data, plugin_id)
      post urlify(:report, :plugin_id => plugin_id),
           "Unable to send report to server.",
           :report => {:data => data, :plugin_id => plugin_id}
    end

    def alert(data, plugin_id)
      post urlify(:alert, :plugin_id => plugin_id),
           "Unable to send alert to server.",
           :alert => data.merge(:plugin_id => plugin_id)
    end

    def error(data, plugin_id)
      post urlify(:error, :plugin_id => plugin_id),
           "Unable to log error on server.",
            :error => data.merge(:plugin_id => plugin_id)
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
        Net::HTTP.start(url.host, url.port) { |http| http.get(uri.path) }
      end
    end
    
    def request(response_handler, error)
      begin
        response = yield
      rescue Timeout::Error
        abort "Request timed out."
      end
      case response
      when Net::HTTPSuccess
        response_handler[response] unless response_handler.nil?
      else
        abort error
      end
    end
  end
end
