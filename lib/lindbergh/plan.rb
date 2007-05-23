require 'ostruct'
class PlanFile < OpenStruct
  def initialize(*args)
    super
    self.errors = []
  end
end

require 'plan.tab'
class PlanParser
  attr_reader :line, :column
  def parse(str)
    @input = str
    @line = 1
    @column = 1
    @planfile = PlanFile.new
    @yydebug = true
    do_parse
  end

  def error(msg)
    @planfile.errors.push [msg,@line,@column]
    $stderr.puts "line #{@line} column #{@column}: #{msg}"
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
                 [:nm, "nmi".u]
               when /\A(km|kilometers?)/
                 [:km, "km".u]
               when /\A(ft?|feet)/
                 [:ft, "feet".u]
               when /\A(m(eter)?)/
                 [:meter, "meter".u]
               when /\A(mph)/
                 [:mph, "mph".u]
               when /\A(knots?|kts?)/
                 [:kts, "kts".u]
               when /\A(kph)/
                 [:kph, "km/hour".u]
               when /\A(fps)/
                 [:fps, "feet/sec".u]
               when /\A(mps)/
                 [:mps, "meters/sec".u]
               when /\A[NSns]/
                 :ns
               when /\A[EWew]/
                 :ew
               when /\A[CFcf]/
                 :cf
               when /\A(\w+)/
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
