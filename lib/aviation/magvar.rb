require 'magvar.so'
require 'aviation/coordinate'
require 'ruby-units'

module Aviation
  module MagVar
    def self.vardip(coord, alt, jd=Date.today.jd)
      lat, lon = coord.to_a
      alt = alt.to('km').scalar if Unit === alt
      c_vardip(lat, lon, alt, jd)
    end
    # coord:: Aviation::Coordinate
    # alt:: altitude above sea level in km
    # jd:: Julian date
    #
    # Returns the magnetic variance in radians
    def self.var(coord, alt, jd=Date.today.jd)
      var, dip = vardip(coord, alt, jd)
      var
    end

    # coord:: Aviation::Coordinate
    # alt:: altitude above sea level in km
    # jd:: Julian date
    #
    # Returns the magnetic dip in radians
    def self.dip(coord, alt, jd=Date.today.jd)
      var, dip = vardip(coord, alt, jd)
      dip
    end
  end
end
