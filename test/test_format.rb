require 'test/unit'
require 'lindbergh/format'

class FormatTest < Test::Unit::TestCase
  def test_cols
    a = "hello\nworld"
    b = "goodbye\ncruel\nworld"
    widths = [-10,6]
    ans = "hello     goodby\nworld      cruel\n           world"
    assert_equal ans, Format.cols([a,b], widths)
  end
end
