require 'aviation/coordinate'
require 'zlib'

module Aviation
  class Checkpoint
    attr_accessor :coord, :id
    def initialize(coord, id)
      @coord, @id = [coord, id]
    end
    def lat; coord.lat; end
    def lon; coord.lon; end
    def lat=(l); coord.lat = l; end
    def lon=(l); coord.lon = l; end
  end

  class Fix < Checkpoint; end

  # alt:: feet above MSL
  # freq:: MHz
  # range:: nm
  class NavAid < Checkpoint
    attr_accessor :alt, :freq, :range, :name
    def initialize(coord, alt, freq, range, id, name)
      super(coord, id)
      @alt, @freq, @range, @name = [alt, freq, range, name]
    end
  end

  # variation:: slaved variation (radians)
  class VOR < NavAid
    attr_accessor :variation
    def initialize(coord, alt, freq, range, variation, id, name)
      super(coord, alt, freq, range, id, name)
      @variation = variation
    end
  end
  class NDB < NavAid; end

  # alt:: feet above MSL
  # runways:: Array of Airport::Runway
  # tower:: Coordinate of tower view
  # beacons:: Array of Airport::Beacon
  # freqs:: Array of Airport::Frequency
  #  
  # As the data file doesn't include an official coordinate for the airport, it
  # is recommended to take either the tower position, the average beacon
  # position, or the average runway center. The calc_coord method will
  # facilitate this.
  class Airport < Checkpoint
    attr_accessor :alt, :name, :runways, :tower, :beacons, :freqs
    def initialize(alt, id, name)
      @alt, @id, @name = [alt, id, name]
      @runways = []
      @beacons = []
      @freqs = []
    end

    # Call this after you have set all the data. It will choose as the
    # coordinate for this Airport either the tower position (if it exists), the
    # average beacon position (if any exist), or the average runway center (if
    # none exist it wouldn't be much of an airport, would it?)
    def calc_coord
      # calculate the average of an array of Coordinate
      def avg(ary)
        raise ArgumentError if ary.empty?
        sum = ary.inject([0,0].coord) {|sum,c| sum + c}
        sum / ary.size
      end

      @coord = if @tower
                 @tower.coord
               elsif @beacons.size > 0
                 avg(@beacons.map {|b| b.coord})
               else
                 avg(@runways.map {|r| r.center})
               end
    end

    # This will call calc_coord when @coord is nil.
    def coord
      calc_coord if @coord.nil?
      @coord
    end

    class Runway
      attr_accessor :center, :number, :heading, :length
      def initialize(center, number, heading, length)
        @center, @number, @heading, @length = [center, number, heading, length]
      end
    end

    class Frequency
      attr_accessor :mhz, :name
      def initialize(mhz, name)
        @mhz, @name = [mhz, name]
      end
    end

    class Beacon
      attr_accessor :coord, :color, :name
      def initialize(coord, color, name)
        @coord, @color, @name = [coord, color, name]
      end
    end
  end

  class SeaplaneBase < Airport
    def initialize(alt, id, name)
      super
    end
  end

  class Heliport < Airport
    def initialize(alt, id, name)
      super
    end
  end

  # Parse apt.dat given a filename and produce a Hash of Arrays of Airport
  # objects (i.e. if there's two KLRU airports, hsh['KLRU'] #=> [klru1, klru2].
  # This is true even if there's only one KLRU). If hsh is passed in, it will
  # be added to rather than producing a new hash. In this way you can produce a
  # Hash of Arrays of Checkpoint objects without a costly merge operation.
  def self.parse_apt(fn, hsh={})
    f = File.open(fn)
    gz = Zlib::GzipReader.new(f)
    gz ||= f

    gz.readline =~ /^[IA]/i or raise "Expected filetype marker in apt.dat"
    gz.readline =~ /^810/i or raise "I only know version 810 of apt.dat"

    apt = nil
    until (l = gz.readline) =~ /^99\s*$/
      l.strip!
      next if l =~ /^\s*$/
      t, l = l.split(' ', 2)
      t = t.to_i
      case t
      when 1,16,17
        alt, hastower, displaybuildings, icao, name = l.split(' ', 5)
        alt = alt.to_i
        case t
        when 1
          apt = Airport.new(alt, icao, name)
        when 16
          apt = SeaplaneBase.new(alt, icao, name)
        when 17
          apt = Heliport.new(alt, icao, name)
        end
        hsh[icao] ||= []
        hsh[icao].push apt
      when 10
        lat, lon, num, hdg, len, thresh, stopwy, width, lighting, sfc, 
          shldr, markings, smoothness, distrem, vasi = l.split(' ', 15)
        num =~ /^([^x]*)x*$/
        num = $1
        next if num.empty? # skip taxiways
        lat = lat.to_f.rad
        lon = lon.to_f.rad
        hdg = hdg.to_f.rad
        len = len.to_i
        center = [lat, lon].coord
        rwy = Airport::Runway.new(center, num, hdg, len)
        apt.runways.push rwy
      when 14
        lat, lon, ht, draw, name = l.split(' ', 5)
        coord = [lat.to_f.rad, lon.to_f.rad].coord
        apt.tower ||= coord
      when 18
        lat, lon, color, name = l.split(' ', 4)
        coord = [lat.to_f.rad, lon.to_f.rad].coord
        color = color.to_i
        apt.beacons.push Airport::Beacon.new(coord, color, name)
      when 15,19
        # ignore startup positions and windsocks
      when (50..59)
        mhz, name = l.split
        mhz = mhz.to_f/100
        apt.freqs.push Airport::Frequency.new(mhz, name)
      else
        raise "Unexpected code in apt.dat (#{t} #{l})"
      end
    end

    f.close
    hsh
  end

  # As with parse_apt, but for nav.dat
  def self.parse_nav(fn, hsh={})
    f = File.open(fn)
    gz = Zlib::GzipReader.new(f) rescue nil
    gz ||= f

    gz.readline =~ /^[IA]/i or raise "Expected filetype marker in nav.dat"
    gz.readline =~ /^810 Version/i or raise "I only know version 810 of nav.dat"

    gz.each_line do |l|
      l.strip!
      next if l =~ /^\s*$/
      code, lat, lon, alt, mhz, range, mp, id, name = l.split(' ', 9)
      code = code.to_i
      case code
      when (4..13)
        # ignore localiser, glideslope, markers, dme
      when 2,3
        coord = [lat.to_f.rad, lon.to_f.rad].coord
        alt = alt.to_i
        freq = freq.to_f/100
        range = range.to_i

        nav = if code == 2
                NDB.new(coord, alt, mhz, range, id, name)
              else
                VOR.new(coord, alt, freq, range, mp.to_f.rad, id, name)
              end

        hsh[id] ||= []
        hsh[id].push nav
      when 99
        break
      else
        raise "Unexpected code in nav.dat (#{l})"
      end
    end

    f.close
    hsh
  end

  # As with parse_apt, but for fix.dat
  def self.parse_fix(fn, hsh={})
    f = File.open(fn)
    gz = Zlib::GzipReader.new(f) rescue nil
    gz ||= f

    gz.readline =~ /^[IA]/i or raise "Expected filetype marker in fix.dat"
    gz.readline =~ /^600 Version/i or raise "I only know verson 600 of fix.dat"

    gz.each_line do |l|
      l.strip!
      next if l =~ /^\s*$/
      break if l =~ /^99\s*$/
      lat, lon, id = l.split
      coord = [lat.to_f.rad, lon.to_f.rad].coord

      hsh[id] ||= []
      hsh[id].push Fix.new(coord, id)
    end

    f.close
    hsh
  end
end
