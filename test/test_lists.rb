require_relative 'helpers'

class TestLists < Test

  def setup
    convert('test/input/lists.md')
  end

  def test_build
    assert_xml
  end

end