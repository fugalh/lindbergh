require 'lindbergh'
require 'zlib'
require 'active_record'
require 'pathname'

# this is an ugly, ugly hack in response to an ugly, ugly bug.
class ActiveRecord::Base
  include Aviation
end

module Aviation
  module LatLon
    def coord
      [lat, lon].coord
    end
    def coord=(c)
      self.lat, self.lon = c.to_a
    end
  end

  class Checkpoint < ActiveRecord::Base
    include LatLon
    # Open dbfile. If init is true, (re)initialize the database (losing all
    # data)
    def self.open(dbfile, init=false)
      if init
        File.delete(dbfile) if File.exist?(dbfile)
      end

      ActiveRecord::Base.establish_connection(:adapter => 'sqlite3',
                                              :database => dbfile)

      if init
        ActiveRecord::Schema.define do
          create_table :checkpoints do |t|
            t.column :type, :string
            t.column :lat, :float
            t.column :lon, :float
            t.column :ident, :string
            t.column :alt, :string
            t.column :freq, :float
            t.column :range, :float
            t.column :name, :string
            t.column :variation, :float
          end
          add_index :checkpoints, :ident
          create_table :towers do |t|
            t.column :airport_id, :integer
            t.column :lat, :float
            t.column :lon, :float
          end
          create_table :runways do |t|
            t.column :airport_id, :integer
            t.column :lat, :float
            t.column :lon, :float
            t.column :num, :string
            t.column :heading, :float
            t.column :length, :float
          end
          create_table :frequencies do |t|
            t.column :airport_id, :integer
            t.column :mhz, :float
            t.column :name, :string
          end
          create_table :beacons do |t|
            t.column :airport_id, :integer
            t.column :lat, :float
            t.column :lon, :float
            t.column :color, :integer
            t.column :name, :string
          end
        end
      end
    end

    # Find the airport/navaid/fix identified by ident that's closest to coord
    def self.closest(coord, ident)
      a = self.find_all_by_ident(ident)
      return nil if a.nil? 
      closest = a.first
      return closest if coord.nil?

      a.each do |cp|
        closest = if coord.dist(cp.coord) < coord.dist(closest.coord)
                    cp
                  else
                    closest
                  end
      end
      closest
    end
  end

  class Fix < Checkpoint; end

  # alt:: feet above MSL
  # freq:: MHz
  # range:: nm
  class NavAid < Checkpoint; end

  # variation:: slaved variation (radians)
  class VOR < NavAid; end
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
    has_one :tower
    has_many :runways
    has_many :frequencies
    has_many :beacons

    # Call this after you have set all the data. It will choose as the
    # coordinate for this Airport either the tower position (if it exists), the
    # average beacon position (if any exist), or the average runway center (if
    # none exist it wouldn't be much of an airport, would it?)
    def calc_coord
      # calculate the average of an array of Coordinate
      def avg(ary)
        sum = ary.inject([0,0].coord) {|sum,c| sum + c}
        return sum if ary.empty?
        sum / ary.size
      end

      save # doesn't work if we don't save first
      self.coord = if tower
                     tower.coord
                   elsif beacons.size > 0
                     avg(beacons.map {|b| b.coord})
                   else
                     avg(runways.map {|r| r.center})
                   end
    end

    # This will call calc_coord when @coord is nil.
    def coord
      calc_coord if lat.nil? or lon.nil?
      super
    end

    alias :freqs :frequencies

    class Tower < ActiveRecord::Base; 
      set_table_name "towers"
      belongs_to :airport
      include LatLon
    end

    class Runway < ActiveRecord::Base
      set_table_name "runways"
      belongs_to :airport
      include LatLon
      alias :center :coord
      alias :center= :coord=
      def to_s
        a = num.to_i
        b = (a+18)%36
        b = 36 if b == 0
        suffix = num[2..-1]
        sprintf("%d%s/%d%s",a,suffix,b,suffix)
      end
    end

    class Frequency < ActiveRecord::Base
      set_table_name "frequencies"
      belongs_to :airport
    end

    class Beacon < ActiveRecord::Base
      set_table_name "beacons"
      belongs_to :airport
      include LatLon
    end
  end

  class SeaplaneBase < Airport; end

  class Heliport < Airport; end

  class Checkpoint

    # Parse {apt,nav,fix}.dat.gz under path
    def self.parse(path)
      path = Pathname.new(path) unless path.is_a? Pathname
      self.parse_apt(path+"apt.dat.gz")
      self.parse_nav(path+"nav.dat.gz")
      self.parse_fix(path+"fix.dat.gz")
    end

    # Parse apt.dat{,.gz} given a filename. An ActiveRecord connection to a
    # database is required.
    # objects (i.e. if there's two KLRU airports, hsh['KLRU'] #=> [klru1,
    # klru2].  This is true even if there's only one KLRU). If hsh is passed
    # in, it will be added to rather than producing a new hash. In this way you
    # can produce a Hash of Arrays of Checkpoint objects without a costly merge
    # operation.
    def self.parse_apt(fn)
      f = File.open(fn)
      gz = Zlib::GzipReader.new(f)
      gz ||= f

      gz.readline =~ /^[IA]/i or raise "Expected filetype marker in apt.dat"
      gz.readline =~ /^810/i or raise "I only know version 810 of apt.dat"

      apt = nil
      until (l = gz.readline) =~ /^99\s*$/
        l.strip!
        next if l.empty?
        t, l = l.split(' ', 2)
        t = t.to_i
        case t
        when 1,16,17
          unless apt.nil?
            apt.calc_coord
            apt.save
          end

          alt, hastower, displaybuildings, icao, name = l.split(' ', 5)
          alt = alt.to_i
          case t
          when 1
            apt = Airport.new(:alt => alt, :ident => icao, :name => name)
          when 16
            apt = SeaplaneBase.new(:alt => alt, :ident => icao, :name => name)
          when 17
            apt = Heliport.new(:alt => alt, :ident => icao, :name => name)
          end

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
          apt.runways.create(:lat => lat, :lon => lon, :num => num, 
                             :heading => hdg, :length => len)

        when 14
          lat, lon, ht, draw, name = l.split(' ', 5)
          lat = lat.to_f.rad
          lon = lon.to_f.rad
          apt.create_tower(:lat => lat, :lon => lon)

        when 18
          lat, lon, color, name = l.split(' ', 4)
          lat = lat.to_f.rad
          lon = lon.to_f.rad
          color = color.to_i
          apt.beacons.create(:lat => lat, :lon => lon, :color => color, 
                             :name => name)
        when 15,19
          # ignore startup positions and windsocks
          #
        when (50..59)
          mhz, name = l.split
          mhz = mhz.to_f/100
          apt.freqs.create(:mhz => mhz, :name => name)

        else
          raise "Unexpected code in apt.dat (#{t} #{l})"
        end
      end

      unless apt.nil?
        apt.calc_coord
        apt.save
      end

      f.close
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
        code, lat, lon, alt, freq, range, mp, ident, name = l.split(' ', 9)
        lat = lat.to_f.rad
        lon = lon.to_f.rad
        code = code.to_i
        case code
        when (4..13)
          # ignore localiser, glideslope, markers, dme
        when 2,3
          alt = alt.to_i
          freq = freq.to_f/100
          range = range.to_i

          nav = if code == 2
                  NDB.new(:lat => lat, :lon => lon, :alt => alt, :freq => freq, 
                          :range => range, :ident => ident, :name => name)
                else
                  VOR.new(:lat => lat, :lon => lon, :alt => alt, :freq => freq, 
                          :range => range, :variation => mp.to_f.rad,  
                          :ident => ident, :name => name)
                end
          nav.save

        when 99
          break

        else
          raise "Unexpected code in nav.dat (#{l})"
        end
      end

      f.close
    end

    # As with parse_apt, but for fix.dat
    def self.parse_fix(fn)
      f = File.open(fn)
      gz = Zlib::GzipReader.new(f) rescue nil
      gz ||= f

      gz.readline =~ /^[IA]/i or raise "Expected filetype marker in fix.dat"
      gz.readline =~ /^600 Version/i or raise "I only know verson 600 of fix.dat"

      gz.each_line do |l|
        l.strip!
        next if l =~ /^\s*$/
        break if l =~ /^99\s*$/
        lat, lon, ident = l.split
        lat = lat.to_f.rad
        lon = lon.to_f.rad

        Fix.new(:lat => lat, :lon => lon, :ident => ident).save
      end

      f.close
    end
  end
end
