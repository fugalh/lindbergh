module Format
  # Format the array of string blocks (containing newlines) into columns
  # of the widths given in the array
  def self.cols(blocks, widths)
    n = blocks.size
    blocks2 = blocks.map {|b| b.split("\n")}
    h = blocks2.map {|b| b.size}.max
    fmt = widths.map {|p| "%#{p}.#{p}s"}.join

    lines = []
    h.times do |i|
      l = blocks2.map {|b| b[i]}
      lines.push sprintf(fmt,*l)
    end
    lines.join("\n")
  end
end
