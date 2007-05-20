require 'test/unit'
require 'aviation/coordinate'

class CoordinateTest < Test::Unit::TestCase
  include Aviation
  def test_array_rad
    assert_equal 9.4*Math::PI/180, [9, 24].rad
    assert_equal -9.4*Math::PI/180, [-9, 24].rad
  end
  def test_array_coord
    ary = [32.321641.rad, -106.746034.rad]
    c1 = ary.coord
    c2 = Coordinate.new(*ary)
    assert_equal c1.lat, c2.lat
    assert_equal c1.lon, c2.lon
  end
end
