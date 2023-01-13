require_relative 'helpers'

class TestSimple < Test

  def setup
    convert('test/input/simple.md')
  end

  def test_build
    assert_xml
  end

end