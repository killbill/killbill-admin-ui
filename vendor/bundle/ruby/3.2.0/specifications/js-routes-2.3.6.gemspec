# -*- encoding: utf-8 -*-
# stub: js-routes 2.3.6 ruby lib

Gem::Specification.new do |s|
  s.name = "js-routes".freeze
  s.version = "2.3.6"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/railsware/js-routes/issues", "changelog_uri" => "https://github.com/railsware/js-routes/blob/v2.3.6/CHANGELOG.md", "documentation_uri" => "https://github.com/railsware/js-routes", "github_repo" => "ssh://github.com/railsware/js-routes", "rubygems_mfa_required" => "true", "source_code_uri" => "https://github.com/railsware/js-routes/tree/v2.3.6" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Bogdan Gusiev".freeze]
  s.date = "2025-12-18"
  s.description = "Exposes all Rails Routes URL helpers as javascript module".freeze
  s.email = "agresso@gmail.com".freeze
  s.extra_rdoc_files = ["LICENSE.txt".freeze]
  s.files = ["LICENSE.txt".freeze]
  s.homepage = "http://github.com/railsware/js-routes".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.4.0".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Brings Rails named routes to javascript".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<railties>.freeze, [">= 5"])
  s.add_runtime_dependency(%q<sorbet-runtime>.freeze, [">= 0"])
  s.add_development_dependency(%q<sprockets-rails>.freeze, [">= 0"])
  s.add_development_dependency(%q<rspec>.freeze, [">= 3.10.0"])
  s.add_development_dependency(%q<bundler>.freeze, [">= 2.2.25"])
  s.add_development_dependency(%q<appraisal>.freeze, [">= 0.5.2"])
  s.add_development_dependency(%q<mini_racer>.freeze, [">= 0.4.0"])
end
