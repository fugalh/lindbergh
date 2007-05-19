require 'magvar.so'

module MagVar
  # lat/lon:: decimal degrees (S and W are negative)
  # alt:: altitude above sea level in km
  # jd:: Julian date
  #
  # Returns the magnetic variance in radians
  def var(lat, lon, alt, jd)
    vardip(lat, lon, alt, jd).first
  end

  # lat/lon:: decimal degrees (S and W are negative)
  # alt:: altitude above sea level in km
  # jd:: Julian date
  #
  # Returns the magnetic dip in radians
  def dip(lat, lon, alt, jd)
    vardip(lat, lon, alt, jd).last
  end
end
