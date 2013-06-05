$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)

require 'kaui/version'

Gem::Specification.new do |s|
  s.name = 'kaui'
  s.version = Kaui::VERSION
  s.summary = 'Killbill Admin UI plugin'
  s.description = 'Rails UI plugin for Killbill administration.'

  s.required_ruby_version = '>= 1.8.7'

  s.license = 'Apache License (2.0)'

  s.author = 'Killbill core team'
  s.email = 'killbilling-users@googlegroups.com'
  s.homepage = 'http://www.killbilling.org'

  s.files = `git ls-files`.split("\n")
  s.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.bindir = 'bin'
  s.executables = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths = %w(lib)

  s.add_dependency 'rails', '~> 3.2.3'
  s.add_dependency 'jquery-rails', '~> 2.0'
  s.add_dependency 'rest-client', '~> 1.6.7'
  s.add_dependency 'money-rails', '~> 0.5.0'
  s.add_dependency 'd3_rails', '~> 2.10.3'
  s.add_dependency 'killbill-client', '~> 0.1.1'

  if defined?(JRUBY_VERSION)
    s.add_development_dependency 'activerecord-jdbc-adapter', '~> 1.2.2'
    s.add_development_dependency 'activerecord-jdbcmysql-adapter', '~> 1.2.2'
    #s.add_development_dependency 'jdbc-mysql', :require => false
  else
    s.add_development_dependency 'mysql2'
  end
end
