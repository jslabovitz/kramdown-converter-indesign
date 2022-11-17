require 'minitest/autorun'
require 'minitest/power_assert'

require 'kramdown-converter-indesign'

class Test < MiniTest::Test

  def convert(input)
    @doc = Kramdown::Document.new(File.read(input))
    @output = @doc.to_indesign.to_s
  end

  def assert_xml
    assert { @output =~ /^<\?xml/ }
  end

end