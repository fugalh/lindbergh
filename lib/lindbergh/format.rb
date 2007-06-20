require 'stringio'
require 'lindbergh/plan'
require 'lindbergh/leg'
require 'lindbergh/waypoint'

class Plan
  def to_s
    s = StringIO.new
    s.print <<-EOF
Checkpoint                         Alt   TC   MH  LegD  TAS   ETE   ATE   Flow
Latitude and Longitude            Temp  Var  Dev  TotD  EGS   ETA   ATA   FLeg
Navaid fixes                      Wind  WCA   CH  RemD  AGS               FRem
------------------------------------------------------------------------------
    EOF
    self.each do |leg|
      s.puts leg.from
      s.puts leg
    end
    s.puts self.last.to
    s.string
  end
end

class Leg
  def sec2clock(seconds)
    a,b = seconds.divmod(60)
    if a == 0
      sprintf(":%02d",b.to_i)
    else
      sprintf("%d:%02d",a,b.to_i)
    end
  end
  def prec(f, p)
    sprintf("%.#{p}f",f)
  end
  def tempC(t)
    t.to('tempC').scalar.round.to_s + 'C'
  end
  # They work the same
  alias :min2clock :sec2clock
  def to_s
    s = StringIO.new
    alt = self.alt && self.alt.to('ft').scalar.round
    tc = self.tc.deg.round%360
    mh = self.mh.deg.round%360
    legd = self.legd && prec(self.legd.to('nmi').scalar,1)
    tas = self.tas && self.tas.to('knots').scalar.round
    ete = self.ete && min2clock(self.ete.to('minutes').scalar)
    ate = nil
    flow = self.fuel_rate && prec(self.fuel_rate.to('gal/h').scalar,1)

    s << sprintf("%38s %4s %4s %5s %4s %5s %5s %6s\n",
                 alt, tc, mh, legd, tas, ete, ate, flow)

    temp = self.temp && tempC(self.temp)
    var = self.var.deg.round
    dev = self.dev && self.dev.deg.round
    totd = prec(self.totd.to('nmi').scalar, 1)
    egs = self.egs && self.egs.to('knots').scalar.round
    eta = self.eta && min2clock(self.eta.to('minutes').scalar)
    ata = nil
    fleg = self.fleg && prec(self.fleg.to('gal').scalar, 1)

    s << sprintf("%38s %4s %4s %5s %4s %5s %5s %6s\n",
                 temp, var, dev, totd, egs, eta, ata, fleg)

    wdir,wkts = self.wind
    wind = self.wind && sprintf("%3d@%d", wdir.deg.round, 
                                wkts.to('knots').scalar.round)
    wca = self.wca && self.wca.deg.round
    ch = self.ch && self.ch.deg.round%360
    remd = self.remd && prec(self.remd.to('nmi').scalar, 1)
    ags = nil
    frem = self.frem && prec(self.frem.to('gal').scalar, 1)

    s << sprintf("%38s %4s %4s %5s %4s %5s %5s %6s",
                 wind, wca, ch, remd, ags, nil, nil, frem)

    s.string
  end
end

module Waypoint
  class Waypoint
    def to_s
      s = StringIO.new
      s.puts name if name
      s.puts comment if comment
      s.puts coord
      s.string
    end
  end
  class Intersection
    def to_s
      s = StringIO.new
      if comment
        s.puts comment
      else
        s.puts "Intersection"
      end
      [0,1].each {|i| s.puts sprintf("%3d° %5s %s", @radials[i].deg.round,
                                        @checkpoints[i].ident,
                                        @checkpoints[i].name)}
      s.puts coord
      s.string
    end
  end
  class RNAV
    def to_s
      s = StringIO.new
      if comment
        s.puts comment
      else
        s.puts "RNAV"
      end
      s.puts sprintf("%d° / %.2g nm from %s %s",
                     @dir.deg.round,
                     @dist.to("nmi").scalar,
                     @checkpoint.ident,
                     @checkpoint.name)
      s.puts coord
      s.string
    end
  end
  class Checkpoint
    def to_s
      case @checkpoint 
      when Aviation::Airport
        # KLRU
        # Las Cruces Intl
        # 4456ft 04/22, 12/30, 08/26
        # 119.02 AWOS
        # 122.7  CTAF/UNICOM
        # 32°17.4'N 106°55.3W

        s = StringIO.new
        s.puts @checkpoint.ident
        s.puts @checkpoint.name
        s.puts sprintf("%dft  %s", @checkpoint.alt, 
                       @checkpoint.runways.map {|r| r.to_s}.join(", "))
        @checkpoint.freqs.each {|f| s.puts sprintf("%6.2f  %s", f.mhz, f.name)}
        s.puts @checkpoint.coord
        s.string
      else
        super
      end
    end
  end
  class Incremental
    def to_s
      sprintf("%s\n%s\n",
              comment || "Incremental",
              coord)
    end
  end
  class Climb
    def to_s
      sprintf("Top of climb to %s at %s\n%s\n",
              alt2, rate.to('feet/min'), coord)
    end
  end
  class Descend
    def to_s
      sprintf("Bottom of descent to %s at %s\n%s\n",
              alt2, rate.to('feet/min'), coord)
    end
  end
end
