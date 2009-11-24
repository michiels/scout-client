$LOAD_PATH << File.expand_path( File.dirname(__FILE__) + '/../lib' )
require 'test/unit'
require 'lib/scout'

class ScoutTesst < Test::Unit::TestCase
  # def setup
  # end

  # def teardown
  # end

  def test_command_creation
    c = Scout::Command::Test.new({},['test/plugins/disk_usage.rb'])
    assert c.run
  end

#  def test_dispatch
#    c = Scout::Command.dispatch(['61ec196f-88dd-403b-9446-da8e4127c9dd', "-s", "http://localhost:4567", "--verbose", ])
#  end

end
