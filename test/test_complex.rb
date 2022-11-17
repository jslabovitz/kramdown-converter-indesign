require_relative 'helpers'

class TestComplex < Test

  def setup
    convert('test/input/complex.md')
  end

  def test_build
    assert_xml
  end

end