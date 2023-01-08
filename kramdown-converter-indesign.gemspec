Gem::Specification.new do |s|
  s.name          = 'kramdown-converter-indesign'
  s.version       = '0.1'
  s.summary       = 'Converts a Kramdown/Markdown document to InDesign\'s ICML format.'
  s.author        = 'John Labovitz'
  s.email         = 'johnl@johnlabovitz.com'
  s.description   = %q{
    Kramdown::Converter::Indesign converts a Kramdown/Markdown document to InDesign's ICML format.
  }
  s.license       = 'MIT'
  s.homepage      = 'http://github.com/jslabovitz/kramdown-converter-indesign'
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_path  = 'lib'

  s.add_dependency 'indesign-rb', '~> 0.1'
  s.add_dependency 'kramdown', '~> 2.4'
  s.add_dependency 'nokogiri', '~> 1.13'

  s.add_development_dependency 'bundler', '~> 2.4'
  s.add_development_dependency 'minitest', '~> 5.16'
  s.add_development_dependency 'minitest-power_assert', '~> 0.3'
  s.add_development_dependency 'rake', '~> 13.0'
end