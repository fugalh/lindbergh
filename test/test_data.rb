require 'test/unit'
require 'aviation/checkpoint'

class DataTest < Test::Unit::TestCase
  def test_data
    t1 = Time.now
    print "Parsing..."
    print "apt..."; $stdout.flush
    hsh = Aviation.parse_apt("data/apt.dat.gz")
    print "nav..."; $stdout.flush
    hsh = Aviation.parse_nav("data/nav.dat.gz",hsh)
    print "fix..."; $stdout.flush
    hsh = Aviation.parse_fix("data/fix.dat.gz",hsh)
    puts "#{Time.now-t1} seconds."

    assert_instance_of Aviation::Airport, hsh['KLRU'].first
    assert_instance_of Aviation::VOR, hsh['AAL'].first
    assert_instance_of Aviation::Fix, hsh['VPPTM'].first
  end
end

