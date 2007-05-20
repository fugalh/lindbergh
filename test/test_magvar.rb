require 'test/unit'
require 'magvar'
require 'rhumb' # for radian conversion
require 'date'

class MagVarTest < Test::Unit::TestCase
  def dec(deg, min=0)
    deg + min/60.0
  end
  def test_var
    d = Date.civil(2007,5,19).jd
    lat = 32.321641.rad
    lon = -106.746034.rad
    alt = 1.37

    # According to
    # http://www.ngdc.noaa.gov/seg/geomag/jsp/struts/calcDeclination
    # the answer is 9° 24' E
    ans = dec(9, 24).rad

    puts MagVar.var(lat, lon, 1.37, d).deg
  end
end
