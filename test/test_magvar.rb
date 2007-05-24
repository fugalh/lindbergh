require 'test/unit'
require 'lindbergh'
require 'date'

class MagVarTest < Test::Unit::TestCase
  include Aviation
  def test_var
    d = Date.civil(2007,5,19).jd
    lat = 32.321641.rad
    lon = -106.746034.rad
    coord = Coordinate.new(lat, lon)
    alt = 1.37

    # According to
    # http://www.ngdc.noaa.gov/seg/geomag/jsp/struts/calcDeclination
    # the answer is 9° 24' E
    ans = [9, 24].rad

    assert_in_delta 1, MagVar.var(coord, alt, d)/ans, 0.01
  end
end
