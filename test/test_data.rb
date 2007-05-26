require 'test/unit'
require 'lindbergh'

class DataTest < Test::Unit::TestCase
  include Aviation
  def setup
    db = "test/lindbergh.db"
    File.delete(db) if File.exist?(db)
    #ActiveRecord::Base.logger = Logger.new "test/log"
    Checkpoint.open("test/data/lindbergh.db",true)
  end

  def test_data
    Checkpoint.parse("test/data")

    klru = Airport.find_by_ident('KLRU')
    assert_instance_of Aviation::Airport, klru
    assert_in_delta -1.86614079737328, klru.lon, 0.001
  end
end

