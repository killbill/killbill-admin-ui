# -*- encoding: utf-8 -*-
# stub: killbill-client 4.0.7 ruby lib

Gem::Specification.new do |s|
  s.name = "killbill-client".freeze
  s.version = "4.0.7"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Killbill core team".freeze]
  s.date = "2025-07-07"
  s.description = "An API client library for Kill Bill.".freeze
  s.email = "killbilling-users@googlegroups.com".freeze
  s.executables = ["retry".freeze]
  s.files = ["bin/retry".freeze]
  s.homepage = "http://www.killbilling.org".freeze
  s.licenses = ["Apache-2.0".freeze]
  s.rdoc_options = ["--exclude".freeze, ".".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 1.8.6".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Kill Bill client library.".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<gem-release>.freeze, ["~> 2.2"])
  s.add_development_dependency(%q<rake>.freeze, ["~> 13.0"])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.4"])
end
