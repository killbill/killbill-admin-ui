# -*- encoding: utf-8 -*-
# stub: cancan 1.6.10 ruby lib

Gem::Specification.new do |s|
  s.name = "cancan".freeze
  s.version = "1.6.10"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.4".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Ryan Bates".freeze]
  s.date = "2013-05-07"
  s.description = "Simple authorization solution for Rails which is decoupled from user roles. All permissions are stored in a single location.".freeze
  s.email = "ryan@railscasts.com".freeze
  s.homepage = "http://github.com/ryanb/cancan".freeze
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Simple authorization solution for Rails.".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 3

  s.add_development_dependency(%q<rspec>.freeze, ["~> 2.6.0"])
  s.add_development_dependency(%q<rails>.freeze, ["~> 3.0.9"])
  s.add_development_dependency(%q<rr>.freeze, ["~> 0.10.11"])
  s.add_development_dependency(%q<supermodel>.freeze, ["~> 0.1.4"])
end
