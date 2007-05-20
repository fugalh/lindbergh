require 'magvar.so'

module Aviation
  module MagVar
    # lat/lon:: decimal radians (S and W are negative)
    # alt:: altitude above sea level in km
    # jd:: Julian date
    #
    # Returns the magnetic variance in radians
    def self.var(lat, lon, alt, jd)
      var, dip = vardip(lat, lon, alt, jd)
      var
    end

    # lat/lon:: decimal degrees (S and W are negative)
    # alt:: altitude above sea level in km
    # jd:: Julian date
    #
    # Returns the magnetic dip in radians
    def self.dip(lat, lon, alt, jd)
      var, dip = vardip(lat, lon, alt, jd)
      dip
    end
  end
end
