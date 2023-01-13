require_relative 'helpers'

class TestEnvironment < Test

  def setup
    convert(*Dir.glob('test/input/environment-*.md'))
  end

  def test_build
    assert_xml
  end

end