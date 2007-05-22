require 'plan.tab'

class PlanParser
  def parse(str)
    @input = str
    @line = 1
    do_parse
  end

  def next_token
    # skip comments and whitespace
    @input.slice! /\A(\s|(#[^\n]*$))+/
    @line += $&.count("\n") if $&

    tok, val = case @input
               when /\A(("[^"]*")|('[^']*'))/
                 [:str, $1]
               when /\A([;\/@'"]|from|via|to|climb|alt|comment|nav|[it]as|wind)/
                 [$1, $1]
               when /\A(deg(rees?)?|°)/
                 :deg
               when /\A(rad(s|ians)?)/
                 :rad
               when /\A(fuel((_|\s+)(amt|amount))?)/
                 :fuel_amount
               when /\A(fuel(_|\s+)rate)/
                 :fuel_rate
               when /\A(fuel(_|\s+)used)/
                 :fuel_used
               when /\A(\d+[\.\d+])/
                 [:number, $1.to_f]
               when /\A(smi?|mi(les?)?)/
                 [:sm, "miles"]
               when /\A(nmi?)/
                 [:nm, "nm"]
               when /\A(km|kilometers?)/
                 [:km, "km"]
               when /\A(ft?|feet)/
                 [:ft, "feet"]
               when /\A(m(eter)?)/
                 [:meter, "meter"]
               when /\A(mph)/
                 [:mph, "mph"]
               when /\A(knots?|kts?)/
                 [:kts, "kts"]
               when /\A(kph)/
                 [:kph, "km/hour"]
               when /\A(fps)/
                 [:fps, "feet/sec"]
               when /\A(mps)/
                 [:mps, "meters/sec"]
               when /\A[NSns]/
                 :ns
               when /\A[EWew]/
                 :ew
               when /\A[CFcf]/
                 :cf
               end
    @input.slice!(0...$&.size)
    [tok, val]
  end
end
