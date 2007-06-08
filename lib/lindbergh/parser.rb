require 'lindbergh'
require 'lindbergh/parser.tab'

class PlanParser
  attr_reader :line, :column
  def parse(str, err_io=$stderr)
    @input = str
    @line = 1
    @column = 1
    @pf = PlanFile.new
    @yydebug = true
    @errors = []
    do_parse
    unless @errors.empty?
      @errors.each {|e| 
        err_io.puts "line #{e.line} column #{e.column}: #{e.msg}" 
      }
      return nil
    end
    @pf.calc
  end

  def error(msg)
    e = OpenStruct.new :msg => msg, :line => @line, :column => @column
    @errors.push e
  end

  def on_error(t, val, vstack)
    @errors.each {|e| 
      err_io.puts "line #{e.line} column #{e.column}: #{e.msg}" 
    }
    raise ParseError, sprintf("\nparse error on line %s column %s value %s (%s)\n",
                              @line, @column,
                              val.inspect, token_to_str(t) || '?')
  end

  def skip(regex)
    @input =~ /\A#{regex}/
    consume($& || "")
  end

  def consume(s)
    @input.slice! 0...s.size
    n = s.count("\n")
    if n > 0
      @column = 1
      s =~ /[^\n]*\Z/
      s = $& || s
    end
    @line += n
    @column += s.size
  end

  def next_token
    # skip comments and whitespace
    skip(/(\s|(#[^\n]*$\n?))+/m)
    return [false, false] if @input.empty?

    tok, val = case @input
               when /\A(\([^)]*\))/
                 [:str, $1]
               when /\A([;\/@'"]|(from|via|to|climb|alt|nav|[it]as|wind|calm|temp|[nsewNSEW])\b)/
                 [$1, $1]
               when /\A(deg(rees?)?\b|°)/
                 [:deg, $&]
               when /\A(rad(s|ians)?)\b/
                 :rad
               when /\A(fuel(_|\s+)rate)\b/
                 :fuel_rate
               when /\A(fuel(_|\s+)used)\b/
                 :fuel_used
               when /\A(fuel((_|\s+)(amt|amount))?)\b/
                 :fuel_amount
               when /\A(\d+(\.\d+)?)\b/
                 [:number, $1.to_f]
               when /\A(smi?|mi(les?)?)\b/
                 [:sm, "miles"]
               when /\A(nmi?\b)/
                 [:nm, "nmi".u]
               when /\A(km|kilometers?)\b/
                 [:km, "km".u]
               when /\A(ft?|feet)\b/
                 [:ft, "feet".u]
               when /\A(m(eter)?)\b/
                 [:meter, "meter".u]
               when /\A(mph)\b/
                 [:mph, "mph".u]
               when /\A(knots?|kts?)\b/
                 [:kts, "kts".u]
               when /\A(kph)\b/
                 [:kph, "km/hour".u]
               when /\A(fps)\b/
                 [:fps, "feet/sec".u]
               when /\A(mps)\b/
                 [:mps, "meters/sec".u]
               when /\A[CFcf]\b/
                 :cf
               when /\A(\w+)\b/
                 [:ident, $1]
               else
                 error("Scan Error")
               end
    consume($&||"")
    [tok, val]
  end

  def add_waypoint(wp)
    unless @leg.nil?
      @leg.to = wp
      @plan.push @leg
    end
    @leg = Leg.new(:from => wp)
  end
end
