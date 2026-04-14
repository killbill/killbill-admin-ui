# -*- encoding: utf-8 -*-
# stub: money-rails 3.0.0 ruby lib

Gem::Specification.new do |s|
  s.name = "money-rails".freeze
  s.version = "3.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/RubyMoney/money-rails/issues", "changelog_uri" => "https://github.com/RubyMoney/money-rails/blob/master/CHANGELOG.md", "rubygems_mfa_required" => "true", "source_code_uri" => "https://github.com/RubyMoney/money-rails/" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Andreas Loupasakis".freeze, "Shane Emmons".freeze, "Simone Carletti".freeze]
  s.date = "1980-01-02"
  s.description = "This library provides integration of RubyMoney - Money gem with Rails".freeze
  s.email = ["alup.rubymoney@gmail.com".freeze]
  s.homepage = "https://github.com/RubyMoney/money-rails".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.1".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Money gem integration with Rails".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<money>.freeze, ["~> 7.0"])
  s.add_runtime_dependency(%q<monetize>.freeze, ["~> 2.0"])
  s.add_runtime_dependency(%q<activesupport>.freeze, [">= 7.0"])
  s.add_runtime_dependency(%q<railties>.freeze, [">= 7.0"])
end
