require 'ostruct'
class PlanFile < OpenStruct
  def initialize(*args)
    super
    self.plans = []
  end
end
class Plan < Array
end
