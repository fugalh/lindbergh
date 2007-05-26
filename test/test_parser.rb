require 'test/unit'
require 'lindbergh'

class ParserTest < Test::Unit::TestCase
  def setup
    @parser = PlanParser.new
  end

  def test_fromto
    pf = @parser.parse "from klru; to ktcs;"
    assert_equal 1, pf.plans.size
    plan = pf.plans.first
    assert_equal 1, plan.size # one leg
    leg = plan.first
    a = leg.from
    b = leg.to
    assert_instance_of Waypoint::Checkpoint, a
    assert_equal 'KLRU', a.cp.ident
    assert_instance_of Waypoint::Checkpoint, b
    assert_equal 'KTCS', b.cp.ident
  end
end
