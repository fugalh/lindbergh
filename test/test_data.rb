require 'test/unit'
require 'lindbergh'

class DataTest < Test::Unit::TestCase
  include Aviation
  def setup
    db = "test/lindbergh.db"
    File.delete(db) if File.exist?(db)
    ActiveRecord::Base.logger = Logger.new "test/log"
    Checkpoint.open("test/lindbergh.db",true)
  end

  def test_data
    t1 = Time.now
    print "Parsing..."
    print "apt..."; $stdout.flush
    Checkpoint.parse_apt("test/apt.dat.gz")
    print "nav..."; $stdout.flush
    Checkpoint.parse_nav("test/nav.dat.gz")
    print "fix..."; $stdout.flush
    Checkpoint.parse_fix("test/fix.dat.gz")
    puts "#{Time.now-t1} seconds."

    assert_instance_of Aviation::Airport, Airport.find_by_ident('KLRU')
  end
end

