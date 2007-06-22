require 'ostruct'
require 'lindbergh/waypoint'

# One leg of a flight plan. Consists of a beginning and ending Waypoint, and
# has all the interesting variables associated with it, like airspeed, wind,
# etc.
class Leg < OpenStruct
  def tc
    from.coord.bearing(to.coord)
  end
  def var
    x = alt || '0 ft'.u
    -from.coord.var(x)
  end
  def wca
    return nil if wind.nil? or tas.nil?
    wd, ws = wind
    xw = Math.sin(wd-tc)*ws # crosswind component
    (xw/tas).to_base.to_f
  end
  def mh
    wca2 = wca || 0
    tc + var + wca2
  end
  def ch
    return nil if dev.nil?
    mh + dev
  end
  def egs
    return nil if tas.nil?
    if wind.nil?
      tas
    else
      wd, ws = wind
      wd += Math::PI
      tas * Math.cos(wca) + ws * Math.cos(wd-tc)
    end
  end
  def ete
    return nil if egs.nil?
    legd / egs
  end
  def legd
    from.coord.dist(to.coord)
  end
end
