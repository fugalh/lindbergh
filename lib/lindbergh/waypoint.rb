require 'lindbergh'

module Waypoint
  class Waypoint
    attr_reader :coord, :name, :city, :comment
    def initialize(coord, ncc)
      @coord = coord
      @name, @city, @comment = ncc
    end
  end

  class Intersection < Waypoint
    attr_reader :checkpoints, :radials
    def initialize(cp1, radial1, cp2, radial2, ncc)
      @checkpoints = [cp1, cp2]
      @radials = [radial1, radial2]
      coord = cp1.coord # TODO
      super coord, ncc
    end
  end

  class RNAV < Waypoint
    attr_reader :checkpoint, :dir, :dist
    def initialize(cp, dir, dist, ncc)
      @checkpoint = cp
      @dir = dir
      @dist = dist
      coord = cp.coord # TODO
      super coord, ncc
    end
  end

  class Checkpoint < Waypoint
    attr_reader :checkpoint
    def initialize(cp)
      @checkpoint = cp
      super cp.coord, nil
    end
  end

  class Incremental < Waypoint
    attr_reader :dist
    def initialize(dist, ncc)
      coord = nil # TODO
      super coord, ncc
    end
  end

  class Climb < Waypoint
    attr_reader :alt, :rate
    def initialize(alt, rate)
      @alt, @rate = [alt, rate]
      coord = nil # TODO
    end
    def seconds
      @alt / @rate
    end
  end
  class Descend < Climb; end
end
