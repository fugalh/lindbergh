require 'lindbergh'

module Waypoint
  class Waypoint
    attr_reader :coord, :name, :city, :comment
    def initialize(coord, comment)
      @coord = coord
      @comment = comment
    end
  end

  class Intersection < Waypoint
    attr_reader :checkpoints, :radials
    def initialize(cp1, radial1, cp2, radial2, comment)
      @checkpoints = [cp1, cp2]
      @radials = [radial1, radial2]
      
      theta1 = radial1
      theta1 += cp1.variation if cp1.is_a?(Aviation::VOR)
      theta2 = radial2
      theta2 += cp2.variation if cp2.is_a?(Aviation::VOR)

      coord = Aviation::Rhumb.intersection(cp1.coord, theta1, cp2.coord, theta2)
      super coord, comment
    end
  end

  class RNAV < Waypoint
    attr_reader :checkpoint, :dir, :dist
    def initialize(cp, dir, dist, comment)
      @checkpoint = cp
      @dir = dir
      @dist = dist
      t = dir
      t += cp.variation if cp.is_a?(Aviation::VOR)
      coord = Aviation::Rhumb.from(@checkpoint.coord, @dist, t)
      super coord, comment
    end
  end

  class Checkpoint < Waypoint
    attr_reader :checkpoint
    alias :cp :checkpoint
    def initialize(cp)
      @checkpoint = cp
      super cp.coord, nil
    end
  end

  class Incremental < Waypoint
    attr_reader :dist
    attr_accessor :from, :to
    def initialize(dist, comment)
      @dist, @comment = [dist, comment]
    end
    def coord
      raise "Not enough context" unless from and to
      t = from.coord.bearing(to.coord)
      Aviation::Rhumb.from(from.coord, dist, t)
    end
  end

  class Climb < Incremental
    attr_reader :alt2, :rate
    attr_accessor :alt1, :tas
    def initialize(alt2, rate)
      @alt2, @rate = [alt2, rate]
    end
    def seconds
      (height / rate).to('seconds')
    end
    def height
      raise "Need previous altitude for climb calculation" unless alt1
      alt2 - alt1
    end
    def alt1
      @alt1
    end
    def dist
      raise "Need TAS for climb calculation" unless tas
      (seconds * tas).to('nmi')
    end
  end

  class Descend < Climb
    def height
      -super
    end
  end
end
