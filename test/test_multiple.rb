require_relative 'helpers'

class TestMultiple < Test

  def setup
    super
    convert(*Dir.glob('test/input/multiple-*.md'))
  end

  def test_build
    assert_xml
  end

end