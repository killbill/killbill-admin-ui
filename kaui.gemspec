$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "kaui/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "kaui"
  s.version     = Kaui::VERSION
  s.authors     = ["Alena Dudzinskaya"]
  s.email       = ["alenad@glam.com"]
  s.homepage    = "https://github.com/ning/killbill-admin-ui"
  s.summary     = "Killbill Admin UI plugin"
  s.description = "Rails UI plugin for Killbill administration."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]
end
