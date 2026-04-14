# -*- encoding: utf-8 -*-
# stub: killbill-assets-ui 1.0.0 ruby lib

Gem::Specification.new do |s|
  s.name = "killbill-assets-ui".freeze
  s.version = "1.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "rubygems_mfa_required" => "true" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Kill Bill core team".freeze]
  s.date = "2025-11-12"
  s.description = "Rails UI plugin for the Deposit plugin.".freeze
  s.email = "killbilling-users@googlegroups.com".freeze
  s.homepage = "https://killbill.io".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Kill Bill Assets UI mountable engine".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<bootstrap-datepicker-rails>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<font-awesome-rails>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<jquery-rails>.freeze, ["~> 4.5.1"])
  s.add_runtime_dependency(%q<rails>.freeze, [">= 7.0"])
end
