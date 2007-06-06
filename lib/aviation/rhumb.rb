require 'aviation/coordinate'
require 'ruby-units'

module Aviation
  # [1] http://www.cwru.edu/artsci/math/alexander/mathmag349-356.pdf
  module Rhumb
    Eccentricity = 0.081
    R = "6378.155 km".u

    # coord[12]:: Aviation::Coordinate
    # Returns a polar vector [r, theta] (km, radians)
    def self.vector(coord1, coord2)
      lat1, lon1 = coord1.to_a
      lat2, lon2 = coord2.to_a
      s1 = sigma(lat1)
      s2 = sigma(lat2)
      ds = s2-s1
      dL = lat2-lat1
      dl = lon2-lon1

      # correct for crossing lon ±180° (date line)
      if dl > Math::PI
        dl -= 2*Math::PI
      elsif dl < -Math::PI
        dl += 2*Math::PI
      end

      # equation 2, bearing from coord1 to coord2 from north
      theta = acot(ds/dl)
      theta += Math::PI if lat2 < lat1 # if southbound
      theta %= 2*Math::PI
      r = R * (lat2-lat1).abs / Math.cos(theta).abs

      [r, theta]
    end

    # ∑ (Sigma)
    def self.sigma(l)
      esinl = Eccentricity * Math.sin(l)
      Math.log(1/Math.cos(l) + Math.tan(l)) - 
        (Eccentricity/2) * Math.log((1 + esinl) / (1 - esinl))
    end

    def self.acot(x)
      Math.atan(1.0/x)
    end
  end
end
