require 'aviation/coordinate'

module Aviation
  class Waypoint
    attr_accessor :coord, :id
    def initialize(coord, id)
      @coord, @id = [coord, id]
    end
    def lat; coord.lat; end
    def lon; coord.lon; end
    def lat=(l); coord.lat = l; end
    def lon=(l); coord.lon = l; end
  end

  class Fix < Waypoint
  end

  # alt:: feet above MSL
  # freq:: MHz
  # range:: nm
  class NavAid < Waypoint
    attr_accessor :alt, :freq, :range, :name
    def initialize(coord, alt, freq, range, name)
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
  class Airport < Waypoint
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
        @type, @mhz, @name = [type, mhz, name]
      end
    end
    class ATC < Frequency; end

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
end
