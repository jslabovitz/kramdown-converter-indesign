require_relative 'helpers'

class TestBlocks < Test

  def setup
    convert('test/input/blocks.md')
  end

  def test_build
    assert_xml
  end

end