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
  def test_arithmetic
    # calculate a simple little average
    r = [
      [32.290541.rad, -106.922206.rad].coord,
      [32.291891.rad, -106.921349.rad].coord,
      [32.284956.rad, -106.922420.rad].coord
    ]
    sum = r.inject([0,0].coord) {|s,c| s+c}
    assert_instance_of Coordinate, sum
    avg = sum/3
    assert_instance_of Coordinate, avg

    sum2 = r.inject(0) {|s,c| s + c.lat}
    avg2 = sum2/3
    assert_equal avg2, avg.lat
  end
end
