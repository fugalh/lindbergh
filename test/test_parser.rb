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
    assert_equal 2, plan.size
    a,b = plan[0..1].map {|w| w.checkpoint}
    assert_instance_of Aviation::Airport, a
    assert_equal 'KLRU', a.ident
    assert_instance_of Aviation::Airport, b
    assert_equal 'KTCS', b.ident
  end
end
