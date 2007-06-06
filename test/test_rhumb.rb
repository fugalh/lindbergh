require 'test/unit'
require 'lindbergh'

class RhumbTest < Test::Unit::TestCase
  include Aviation
  def test_dist
    nyc = [[40,45].rad, -[73,58].rad].coord
    london = [[[51,32].rad, -[0,10].rad].coord, 5802]
    bogota = [[[4,32].rad, -[74,5].rad].coord, 4030] # colongitudinal
    beijing = [[[39,55].rad, [116,23].rad].coord, 14380] # colatitudinal
    canberra = [[-[35,31].rad, [149,10].rad].coord, 16408]

    %w{london bogota beijing canberra}.each do |c|
      coord = ex = nil
      instance_eval "coord,ex = #{c}"
      # test within 1% because apparently he uses the spherical approach in
      # doing his calculations and we use the elliptical one.
      dist, bearing = Rhumb.vector(nyc, coord)
      assert_in_delta 1, dist.to('km').abs/ex, 0.01, c
    end
  end
  def test_bearing
    # KLRU to KWSD measures 83° true course on my sectional
    # we should be close to that
    klru = [[32,17.5].rad, -[106,55.5].rad].coord
    kwsd = [[32,20.5].rad, -[106,24].rad].coord
    r, b = Rhumb.vector(klru, kwsd)
    assert_in_delta 1, b.deg/83, 0.01, b.deg
  end
end
