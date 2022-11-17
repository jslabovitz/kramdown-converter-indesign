require_relative 'helpers'

class TestGettysburg < Test

  def setup
    convert('test/input/gettysburg.md')
  end

  def test_build
    assert_xml
  end

end