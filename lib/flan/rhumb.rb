# [1] http://www.cwru.edu/artsci/math/alexander/mathmag349-356.pdf

class Numeric
  def rad
    self * Math::PI/180
  end
  def deg
    self * 180/Math::PI
  end
end

module Flan
  module Rhumb
    Eccentricity = 0.081
    R = 6378.155 # km

    # lat/lon are in decimal degrees
    # Returns a polar vector [r, theta] (km, radians)
    def self.vector(lat1, lon1, lat2, lon2)
      s1 = sigma(lat1.rad)
      s2 = sigma(lat2.rad)
      ds = s2-s1
      dL = (lat2-lat1).rad
      dl = (lon2-lon1).rad

      # correct for crossing lon ±180° (date line)
      if dl > Math::PI
        dl -= 2*Math::PI
      elsif dl < -Math::PI
        dl += 2*Math::PI
      end

      theta = acot(ds/dl)
      r = R * (lat2-lat1).abs.rad / Math.cos(theta).abs

      [r, theta]
    end

    def self.dist(lat1, lon1, lat2, lon2)
      vector(lat1, lon1, lat2, lon2).first
    end

    def self.bearing(lat1, lon1, lat2, lon2)
      vector(lat1, lon1, lat2, lon2).last
    end

    # ∑ (Sigma)
    def self.sigma(l)
      esinl = Eccentricity * Math.sin(l)
      Math.log(1/Math.cos(l) + Math.tan(l)) - 
        (Eccentricity/2) * Math.log((1 + esinl) / (1 - esinl))
    end

    # arc cotangent
    def self.acot(x)
      Math::PI / 2 - Math.atan(x)
    end
  end
end
