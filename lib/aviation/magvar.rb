require 'magvar.so'
require 'aviation/coordinate'

module Aviation
  module MagVar
    # coord:: Aviation::Coordinate
    # alt:: altitude above sea level in km
    # jd:: Julian date
    #
    # Returns the magnetic variance in radians
    def self.var(coord, alt, jd)
      lat, lon = coord.to_a
      var, dip = vardip(lat, lon, alt, jd)
      var
    end

    # coord:: Aviation::Coordinate
    # alt:: altitude above sea level in km
    # jd:: Julian date
    #
    # Returns the magnetic dip in radians
    def self.dip(coord, alt, jd)
      lat, lon = coord.to_a
      var, dip = vardip(lat, lon, alt, jd)
      dip
    end
  end
end
