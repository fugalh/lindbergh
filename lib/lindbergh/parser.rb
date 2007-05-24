require 'lindbergh/plan'
require 'lindbergh/waypoint'
require 'lindbergh/parser.tab'
require 'ruby-units'

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
    if @errors.empty?
      return @pf
    else
      @errors.each {|e| 
        err_io.puts "line #{e.line} column #{e.column}: #{e.msg}" 
      }
      return nil
    end
  end

  def error(msg)
    e = OpenStruct.new :msg => msg, :line => @line, :column => @column
    @errors.push e
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
    skip(/\s+|(#[^\n]$)+/m)
    return [false, false] if @input.empty?

    tok, val = case @input
               when /\A(("[^"]*")|('[^']*'))/
                 [:str, $1]
               when /\A([;\/@'"]|(from|via|to|climb|alt|comment|nav|[it]as|wind)\b)/
                 [$1, $1]
               when /\A(deg(rees?)?\b|°)/
                 :deg
               when /\A(rad(s|ians)?)\b/
                 :rad
               when /\A(fuel((_|\s+)(amt|amount))?)\b/
                 :fuel_amount
               when /\A(fuel(_|\s+)rate)\b/
                 :fuel_rate
               when /\A(fuel(_|\s+)used)\b/
                 :fuel_used
               when /\A(\d+[\.\d+])/
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
               when /\A[NSns]\b/
                 :ns
               when /\A[EWew]\b/
                 :ew
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
end

if $0 == __FILE__
  puts PlanParser.new.parse(ARGF.read).inspect
end
