require 'minitest/autorun'
require 'minitest/power_assert'

require 'kramdown-converter-indesign'

class Test < MiniTest::Test

  InputDir = Path.new('test/input')
  OutputDir = Path.new('test/output')

  def setup
    OutputDir.mkpath unless OutputDir.exist?
  end

  def output_path(extension)
    (OutputDir / "#{self.class.to_s.split('::').last}-#{name}").add_extension(extension)
  end

  def convert(*files, **params)
    @output = Kramdown::Converter::Indesign.convert_files(files, **params)
    # ;;puts @output
    @output_file = output_path('.icml')
    @output_file.write(@output)
  end

  def assert_xml
    xml = @output.to_xml
    assert { xml =~ /^<\?xml/ }
  end

end