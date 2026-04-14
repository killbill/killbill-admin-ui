# -*- encoding: utf-8 -*-
# stub: mustache-js-rails 4.1.0.4 ruby lib

Gem::Specification.new do |s|
  s.name = "mustache-js-rails".freeze
  s.version = "4.1.0.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "homepage_uri" => "https://github.com/knapo/mustache-js-rails", "source_code_uri" => "https://github.com/knapo/mustache-js-rails" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Krzysztof Knapik".freeze]
  s.date = "2024-06-04"
  s.email = ["knapo@knapo.net".freeze]
  s.homepage = "https://github.com/knapo/mustache-js-rails".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.0.0".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "mustache.js and jQuery.mustache.js integration for Rails 3.1+ asset pipeline".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<railties>.freeze, [">= 3.1"])
  s.add_development_dependency(%q<rake>.freeze, [">= 0"])
  s.add_development_dependency(%q<release>.freeze, [">= 0"])
end
