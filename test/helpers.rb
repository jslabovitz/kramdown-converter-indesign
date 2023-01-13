require 'minitest/autorun'
require 'minitest/power_assert'

require 'kramdown-converter-indesign'

class Test < MiniTest::Test

  def convert(*files)
    @output = Kramdown::Converter::Indesign.convert_files(files)
    # ;;puts @output
    FileUtils.mkpath("test/output")
    File.write("test/output/#{self.class}_#{name}.icml", @output)
  end

  def assert_xml
    xml = @output.to_xml
    assert { xml =~ /^<\?xml/ }
  end

end