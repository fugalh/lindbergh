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
    -from.coord.var(alt || 0)
  end
  def wca
    return nil if wind.nil? or tas.nil?
    wdir, wkts = wind
    Math.asin(wkts*Math.sin(tc - wdir + Math::PI)/tas)
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
    wdir, wkts = wind
    tas * Math.cos(wca) + wkts * Math.cos(tc - wdir + Math::PI)
  end
  def ete
    return nil if egs.nil?
    legd / egs
  end
  def legd
    from.coord.dist(to.coord)
  end
end
