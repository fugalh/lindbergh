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
    # carry over variables
    vbl = %w(alt temp wind tc dev tas fuel_rate)
    carry = {}
    vbl.each {|v| carry[v] = self.first.send(v)}
    totd = '0 nmi'.u
    remd = self.inject('0 nmi'.u) {|s,l| s + l.legd}
    eta = "0 sec".u
    frem = nil

    self.each do |l|
      totd += l.legd
      remd -= l.legd
      l.totd = totd
      l.remd = remd

      vbl.each do |v| 
        carry[v] = l.send(v) || carry[v]
        l.send(v + '=', carry[v])
      end

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
