$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "kaui/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "kaui"
  s.version     = Kaui::VERSION
  s.authors     = ["Alena Dudzinskaya"]
  s.email       = ["alenad@glam.com"]
  s.homepage    = "https://github.com/killbill/killbill-admin-ui"
  s.summary     = "Killbill Admin UI plugin"
  s.description = "Rails UI plugin for Killbill administration."

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.bindir        = 'bin'
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency 'rails', '~> 3.2.3'
  s.add_dependency 'jquery-rails', '~> 2.0'
  s.add_dependency 'rest-client', '~> 1.6.7'
  s.add_dependency 'money-rails', '~> 0.5.0'
  s.add_dependency 'd3_rails', '~> 2.10.0'
end
