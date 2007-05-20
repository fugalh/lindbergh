require 'test/unit'
require 'flan/rhumb'

class RhumbTest < Test::Unit::TestCase
  include Flan
  def dec(deg, min=0)
    deg + min/60.0
  end
  def test_dist
    nyc = [dec(40,45), -dec(73,58)]
    london = [dec(51,32), -dec(0,10), 5802]
    bogota = [dec(4,32), -dec(74,5), 4030] # colongitudinal
    beijing = [dec(39,55), dec(116,23), 14380] # colatitudinal
    canberra = [-dec(35,31), dec(149,10), 16408]

    %w{london bogota beijing canberra}.each do |c|
      lat1,lon1 = nyc
      lat2 = lon2 = ex = nil
      instance_eval "lat2,lon2,ex = #{c}"
      # test within 1% because apparently he uses the spherical approach in
      # doing his calculations and we use the elliptical one.
      assert_in_delta 1, Rhumb.dist(lat1,lon1, lat2,lon2)/ex, 0.01, c
    end
  end
  def test_bearing
    # KLRU to KWSD measures 83° true course on my sectional
    # we should be close to that
    lat1, lon1 = klru = [dec(32,17.5), -dec(106,55.5)]
    lat2, lon2 = kwsd = [dec(32,20.5), -dec(106,24)]
    b = Rhumb.bearing(lat1,lon1, lat2, lon2)
    assert_in_delta 1, b.deg/83, 0.01, b.deg
  end
end
