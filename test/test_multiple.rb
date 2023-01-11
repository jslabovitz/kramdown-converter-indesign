require_relative 'helpers'

class TestMultiple < Test

  def setup
    convert(*Dir.glob('test/input/multiple-*.md'))
  end

  def test_build
    ;;puts @output
    assert_xml
  end

end