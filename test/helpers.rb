require 'minitest/autorun'
require 'minitest/power_assert'

require 'kramdown-converter-indesign'

class Test < MiniTest::Test

  def convert(input)
    @doc = Kramdown::Document.new(File.read(input), format: true)
    @output = @doc.to_indesign
    FileUtils.mkpath("test/output")
    File.write("test/output/#{self.class}_#{name}.icml", @output)
  end

  def assert_xml
    assert { @output =~ /^<\?xml/ }
  end

end