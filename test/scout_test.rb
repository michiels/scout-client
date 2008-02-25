require 'test/unit'
require File.dirname(__FILE__) + '/../lib/scout'
require "logger"

class ScoutTest < Test::Unit::TestCase

  SCOUT_TEST_SERVER = "http://localhost:4000/"
  SCOUT_TEST_VALID_CLIENT_KEY = "valid key goes here"
  SCOUT_TEST_VALID_PLUGIN_ID = "valid plugin id goes here"

  def setup
    @log = Logger.new('test.log')
    @scout_server = create_scout_server(SCOUT_TEST_SERVER,
                                        SCOUT_TEST_VALID_CLIENT_KEY)
  end
  
  def teardown
    File.delete('test.log')
  end

  def test_create
    assert @scout_server
  end

  def test_should_initialize_new_server
    ["@history_file", "@client_key", "@logger", "@server", "@history"].each do |var|
      assert @scout_server.instance_variables.include?(var)
    end
  end
  
  def test_should_send_report
    report = {:server_load => "99.99"}
    assert_does_not_exit { @scout_server.send_report(report, SCOUT_TEST_VALID_PLUGIN_ID) }    
    assert_log_contains("Report sent")
  end
  
  def test_should_not_send_report_with_invalid_client_key
    @scout_server_invalid_client_key = create_scout_server(SCOUT_TEST_SERVER, 
                                       "1111-2222-3333-4444-5555")
    report = {:server_load => "99.99"}
    assert_does_exit { @scout_server_invalid_client_key.send_report(report, SCOUT_TEST_VALID_PLUGIN_ID) }
    assert_log_contains("Unable to send report to server")
    assert_log_contains("An HTTP error occurred:  exit")
  end
  
  def test_should_not_send_report_with_invalid_plugin_id
    report = {:server_load => "99.99"}
    assert_does_exit { @scout_server.send_report(report, 9999999999) }
    assert_log_contains("Unable to send report to server")
    assert_log_contains("An HTTP error occurred:  exit")
  end
  
  def test_should_not_send_report_with_plugin_not_belonging_to_client
    report = {:server_load => "99.99"}
    assert_does_exit { @scout_server.send_report(report, 4) }
    assert_log_contains("Unable to send report to server")
    assert_log_contains("An HTTP error occurred:  exit")    
  end
  
  def create_scout_server(server, client_key, history=File.join("/tmp", "client_history.yaml"), logger=@log)
    Scout::Server.new(server, client_key, history, logger)
  end
  
  def assert_log_contains(pattern)
    @log_file = File.read('test.log')
    assert @log_file.include?(pattern), "log does not include the pattern:\n#{pattern}\nlog contains:\n#{@log_file}"
  end
  
  # asserts that the program actually exits, terminating.
  def assert_does_exit(&block)
    begin
      yield
    rescue SystemExit
      assert true, "Expected program to not exit, but program did exit."
      return
    end
    flunk "Expected program to exit, but program did not exit."
  end
  
  # asserts that the program does not exit.
  def assert_does_not_exit(&block)
    begin
      yield
    rescue SystemExit
      flunk "Expected program to not exit, but program did exit."
      return
    end
    assert true, "Expected program to not exit, but program did exit."
  end
  
end