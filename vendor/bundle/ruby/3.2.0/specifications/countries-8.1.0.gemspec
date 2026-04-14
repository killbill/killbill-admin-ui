# -*- encoding: utf-8 -*-
# stub: countries 8.1.0 ruby lib

Gem::Specification.new do |s|
  s.name = "countries".freeze
  s.version = "8.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/countries/countries/issues", "changelog_uri" => "https://github.com/countries/countries/blob/master/CHANGELOG.md", "rubygems_mfa_required" => "true", "source_code_uri" => "https://github.com/countries/countries", "wiki_uri" => "https://github.com/countries/countries/wiki" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Josh Robinson".freeze, "Joe Corcoran".freeze, "Russell Osborne".freeze, "Pedro Moreira".freeze]
  s.date = "1980-01-02"
  s.description = "All sorts of useful information about every country packaged as pretty little country objects. It includes data from ISO 3166".freeze
  s.email = ["hexorx@gmail.com".freeze, "russell@burningpony.com".freeze, "pedro@codecreations.tech".freeze]
  s.homepage = "https://github.com/countries/countries".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.2".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Gives you a country object full of all sorts of useful information.".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<unaccent>.freeze, ["~> 0.3"])
  s.add_development_dependency(%q<activesupport>.freeze, [">= 3", "< 8"])
  s.add_development_dependency(%q<nokogiri>.freeze, [">= 1.8"])
  s.add_development_dependency(%q<rspec>.freeze, [">= 3"])
  s.add_development_dependency(%q<simplecov>.freeze, ["~> 0.22"])
end
