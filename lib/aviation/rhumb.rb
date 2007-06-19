require 'aviation/coordinate'
require 'ruby-units'

module Aviation
  # [1] http://www.cwru.edu/artsci/math/alexander/mathmag349-356.pdf
  module Rhumb
    Eccentricity = 0.081
    R = "6378.155 km".u
    Epsilon = 2**(-23)

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
    def self.sigma(lat)
      # elliptical
      #esinl = Eccentricity * Math.sin(lat)
      #Math.log(1/Math.cos(lat) + Math.tan(lat)) - 
      #  (Eccentricity/2) * Math.log((1 + esinl) / (1 - esinl))
      
      # XXX Spherical here, so the inverse works. It'll be good enough until we
      # can figure out the inverse of the ellipsoid sigma.
      Math.log(Math.tan(0.5*(Math::PI/2 + lat)))
    end

    # ∑ inverse XXX not close enough. need the elliptical one
    def self.cosigma(s)
      2 * Math.atan(Math.exp(s)) - Math::PI/2
    end

    def self.acot(x)
      Math.atan(1.0/x)
    end
    # coord:: Starting point (Aviation::Coordinate)
    # r:: distance (Unit)
    # theta:: bearing (radians)
    #
    # Returns the destination coordinate
    def self.from(coord, r, theta)
      lat1, lon1 = coord.to_a

      m = 1/Math.tan(theta)
      if m.abs < Epsilon
        dL = 0
        dl = (r/R).to_base.scalar
        dl = -dl if Math.sin(theta) < 0 # westbound
      else
        dL = r/(R * Math.sqrt(1 + (1/(m*m))))
        dL = dL.to_base.scalar
        dL = -dL if Math.cos(theta) < 0 # southbound
        dE = sigma(lat1 + dL) - sigma(lat1)
        dl = dE/m
      end

      [lat1 + dL, lon1 + dl].coord
    end

    # Returns the coordinate for the intersection of the two coordinates along
    # the true course radials.
    def self.intersection(coord1, theta1, coord2, theta2)
      s1 = sigma(coord1.lat)
      s2 = sigma(coord2.lat)
      l1 = coord1.lon
      l2 = coord2.lon
      m1 = 1/Math.tan(theta1)
      m2 = 1/Math.tan(theta2)

      b1 = s1 - m1*l1
      b2 = s2 - m2*l2
      # m1 x + b1 = m2 x + b2
      lon = (b2-b1)/(m1-m2)
      s = m1*lon + b1
      lat = cosigma(s)

      [lat, lon].coord
    end
  end
end
