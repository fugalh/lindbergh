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
    var = %w(alt temp wind tc dev tas flow)
    var.each {|v| instance_eval "#{v} = self.first.#{v}"}
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

      var.each do |v| 
        instance_eval "#{v} = l.#{v} || #{v}; l.#{v} = #{v}"
      end
      l.fleg = l.flow * ete unless ete.nil?
    end
  end
end
