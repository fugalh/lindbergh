require 'aviation/rhumb'
require 'aviation/magvar'
require 'date'

class Numeric
  def rad
    self * Math::PI/180
  end
  def deg
    self * 180/Math::PI
  end
  def degmin
    d = deg
    m = (d - d.to_i).abs * 60
    [d.to_i, m]
  end
  def degminsec
    d, m = degmin
    s = (m - m.to_i) * 60
    m = m.to_i
    [d, m, s]
  end
end

class Array
  # convert [degrees], [degrees, minutes], or [degrees, minutes, seconds] to
  # radians.
  def rad
    case size
    when 1
      l = self[0]
      @lat = l.rad
    when 2
      d,m = self
      if d < 0
        @lat = (d - m/60.0).rad
      else
        @lat = (d + m/60.0).rad
      end
    when 3
      d,m,s = l
      if d < 0
        @lat = (d - m/60.0 - s/(60.0**2)).rad
      else
        @lat = (d + m/60.0 + s/(60.0**2)).rad
      end
    else
      raise ArgumentError
    end
  end
  def coord
    raise ArgumentError unless self.size == 2
    lat, lon = self
    Aviation::Coordinate.new(lat, lon)
  end
end

module Aviation
  # Latitude/Longitude coordinate. Radians, S and W are negative.
  class Coordinate
    attr_accessor :lat, :lon
    def initialize(lat, lon)
      @lat = lat
      @lon = lon
    end

    def to_a
      [@lat, @lon]
    end

    # Rhumb [distance (Unit), bearing (radians)] from here to there
    def rhumb(there)
      Rhumb.vector(self, there)
    end

    # Rhumb distance from here to there (Unit)
    def distance(there)
      rhumb(there).first
    end
    alias :dist :distance

    # Rhumb bearing from here to there (radians)
    def bearing(there)
      rhumb(there).last
    end

    # Magnetic Variation, at this lat/lon and altitude in meters above sea
    # level, and Julian date
    def variation(alt=0, jd=Date.today.jd)
      var, dip = MagVar.vardip(@lat, @lon, alt*1000, jd)
      var
    end
    alias :var :variation

    # String representation, like  32°19.298'N 106°44.762'W
    def to_s
      d1,m1 = @lat.degmin
      d2,m2 = @lon.degmin

      if d1 < 0
        d1 = -d1
        ns = "S"
      else 
        ns = "N"
      end

      if d2 < 0
        d2 = -d2
        ew = "W"
      else 
        ew = "E"
      end

      sprintf "%3d°%6.3f'%s %3d°%6.3f'%s", d1, m1, ns, d2, m2, ew
    end

    def +(o)
      case o
      when Coordinate
        [@lat + o.lat, @lon + o.lon].coord
      when Numeric
        [@lat + o, @lon + o].coord
      else
        raise ArgumentError
      end
    end
    def -(o)
      self + (-o)
    end
    def -@
      [-@lat, -@lon].coord
    end
    def /(scalar)
      [@lat / scalar, @lon / scalar].coord
    end
    def *(scalar)
      [@lat * scalar, @lon * scalar].coord
    end
  end
end
