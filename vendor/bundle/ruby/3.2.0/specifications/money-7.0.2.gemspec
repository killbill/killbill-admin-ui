# -*- encoding: utf-8 -*-
# stub: money 7.0.2 ruby lib

Gem::Specification.new do |s|
  s.name = "money".freeze
  s.version = "7.0.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/RubyMoney/money/issues", "changelog_uri" => "https://github.com/RubyMoney/money/blob/main/CHANGELOG.md", "rubygems_mfa_required" => "true", "source_code_uri" => "https://github.com/RubyMoney/money/" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Shane Emmons".freeze, "Anthony Dmitriyev".freeze]
  s.date = "2025-12-10"
  s.description = "A Ruby Library for dealing with money and currency conversion.".freeze
  s.email = ["shane@emmons.io".freeze, "anthony.dmitriyev@gmail.com".freeze]
  s.homepage = "https://rubymoney.github.io/money".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.1".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "A Ruby Library for dealing with money and currency conversion.".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<bigdecimal>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<i18n>.freeze, ["~> 1.9"])
end
