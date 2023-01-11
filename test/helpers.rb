require 'minitest/autorun'
require 'minitest/power_assert'

require 'kramdown-converter-indesign'

class Test < MiniTest::Test

  def convert(*files)
    icml = nil
    files.each do |file|
      input = File.read(file).strip
      input += "\n\n" unless file == files[-1]
      icml = Kramdown::Document.new(input, indesign_append_to_icml: icml).to_indesign
    end
    @output = icml.to_s
    FileUtils.mkpath("test/output")
    File.write("test/output/#{self.class}_#{name}.icml", @output)
  end

  def assert_xml
    assert { @output =~ /^<\?xml/ }
  end

end