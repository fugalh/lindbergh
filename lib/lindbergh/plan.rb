require 'ostruct'

class PlanFile < Array
  def calc
    self.each {|p| p.calc}
    self
  end
end

class Plan < Array
  # carry over variables
  # Calculate totd, remd, fleg, frem for each leg
  def calc
    self.each_with_index do |l,i|
      w = l.to
      next unless w.is_a?(Waypoint::Incremental)

      l2 = self[i+1..-1].find {|x| not x.to.is_a?(Waypoint::Incremental)}
      raise "Last waypoint can't be incremental." unless l2

      w.from = l.from
      w.to = l2.to
    end

    # carry over variables
    carry = {}
    self.each_with_index do |l,i|
      %w(alt temp wind dev tas fuel_rate).each do |v| 
        carry[v] = l.send(v) || carry[v]
        l.send(v + '=', carry[v])
      end

      if l.to.is_a?(Waypoint::Climb)
        l.to.alt1 = l.alt
        l.to.tas = l.tas
        l2 = self[i+1]
        l2.alt = l.to.alt2 if l2
      end
    end

    totd = '0 nmi'.u
    remd = self.inject('0 nmi'.u) {|s,l| s + l.legd}
    eta = "0 min".u
    frem = nil

    self.each do |l|
      totd += l.legd
      remd -= l.legd
      l.totd = totd
      l.remd = remd

      ete = l.ete
      unless ete.nil?
        eta += ete
        l.eta = eta
      end

      frem = l.fuel_amount || frem
      frem -= l.fuel_used unless frem.nil? or l.fuel_used.nil?
      unless l.fuel_rate.nil? or ete.nil?
        l.fleg = l.fuel_rate * ete 
        frem -= l.fleg unless frem.nil?
      end
      l.frem = frem
    end
  end
end
