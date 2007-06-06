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
    vbl = %w(alt temp wind tc dev tas flow)
    carry = {}
    vbl.each {|v| carry[v] = self.first.send(v)}
    totd = '0 nmi'.u
    remd = self.inject('0 nmi'.u) {|s,l| s + l.legd}
    eta = "0 sec".u

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

      vbl.each do |v| 
        carry[v] = l.send(v) || carry[v]
        l.send(v + '=', carry[v])
      end
      l.fleg = l.flow * ete unless ete.nil? or l.flow.nil?
    end
  end
end
