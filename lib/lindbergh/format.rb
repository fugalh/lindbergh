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
    t.to('tempC').abs.round.to_s + 'C'
  end
  # They work the same
  alias :min2clock :sec2clock
  def to_s
    s = StringIO.new
    alt = self.alt && self.alt.to('ft').abs.round
    tc = self.tc.deg.round%360
    mh = self.mh.deg.round%360
    legd = self.legd && prec(self.legd.to('nmi').abs,1)
    tas = self.tas && self.tas.to('knots').abs.round
    ete = self.ete && min2clock(self.ete.to('minutes').abs)
    ate = nil
    flow = self.flow && prec(self.flow.to('gallons/hour').abs,1)

    s << sprintf("%38s %4s %4s %5s %4s %5s %5s %6s\n",
                 alt, tc, mh, legd, tas, ete, ate, flow)

    temp = self.temp && tempC(self.temp)
    var = self.var.deg.round
    dev = self.dev && self.dev.deg.round
    totd = prec(self.totd.to('nmi').abs, 1)
    egs = self.egs && self.egs.to('knots').abs.round
    eta = self.ete && min2clock(self.ete.to('minutes').abs)
    ata = nil
    fleg = self.fleg && prec(self.fleg.to('gallons/hour').abs, 1)

    s << sprintf("%38s %4s %4s %5s %4s %5s %5s %6s\n",
                 temp, var, dev, totd, egs, eta, ata, fleg)

    wind = self.wind && sprintf("%3d@%d", *(self.wind.map {|w| w.round}))
    wca = self.wca && self.wca.deg.round
    ch = self.ch && self.ch.deg.round%360
    remd = self.remd && prec(self.remd.to('nmi').abs, 1)
    ags = nil
    frem = self.frem && prec(self.frem.to('gallons/hour').abs, 1)

    s << sprintf("%38s %4s %4s %5s %4s %5s %5s %6s",
                 wind, wca, ch, remd, ags, nil, nil, frem)

    s.string
  end
end

class Waypoint::Waypoint
  def to_s
    s = StringIO.new
    s.puts name
    s.puts coord
    s.string
  end
end
