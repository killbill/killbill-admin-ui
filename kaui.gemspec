$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)

require 'kaui/version'

Gem::Specification.new do |s|
  s.name = 'kaui'
  s.version = Kaui::VERSION
  s.summary = 'Killbill Admin UI mountable engine'
  s.description = 'Rails UI plugin for Killbill administration.'

  s.required_ruby_version = '>= 1.8.7'

  s.license = 'Apache License (2.0)'

  s.author = 'Killbill core team'
  s.email = 'killbilling-users@googlegroups.com'
  s.homepage = 'http://www.killbill.io'

  s.files = `git ls-files`.split("\n")
  s.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.bindir = 'bin'
  s.executables = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths = %w(lib)

  s.add_dependency 'rails', '~> 4.2.0'

  # Transitional gems (for rails upgrade)
  s.add_dependency 'protected_attributes', '~> 1.0.6'

  s.add_dependency 'mime-types', '~> 2.0'
  s.add_dependency 'js-routes', '~> 1.1'
  s.add_dependency 'jquery-rails', '~> 3.0.4'
  s.add_dependency 'jquery-datatables-rails', '~> 3.3.0'
  s.add_dependency 'money-rails', '~> 1.3.0'
  s.add_dependency 'd3_rails', '~> 3.2.8'
  s.add_dependency 'killbill-client', '~> 0.22'
  s.add_dependency 'twitter-bootstrap-rails', '~> 3.2.0'
  s.add_dependency 'bootstrap-datepicker-rails', '~> 1.4.0'
  s.add_dependency 'devise', '~> 3.4.1'
  s.add_dependency 'cancan', '~> 1.6.10'
  s.add_dependency 'carmen-rails', '~> 1.0.0'
  s.add_dependency 'symmetric-encryption', '~> 3.6.0'
  s.add_dependency 'sass-rails', '~> 5.0.2'
  s.add_dependency 'less-rails', '~> 2.7.0'
  s.add_dependency 'concurrent-ruby', '~> 1.0.0.pre1'

  s.add_development_dependency 'fakeweb', '~> 1.3'
  s.add_development_dependency 'multi_json', '~> 1.11'
  s.add_development_dependency 'rake', '>= 0.8.7'
  s.add_development_dependency 'pry-rails'
  s.add_development_dependency 'simplecov'

  if defined?(JRUBY_VERSION)
    s.add_development_dependency 'therubyrhino', '~> 2.0.4'

    s.add_development_dependency 'activerecord-jdbc-adapter', '~> 1.3.9'
    s.add_development_dependency 'activerecord-jdbcmysql-adapter', '~> 1.3.9'
    s.add_development_dependency 'activerecord-jdbcsqlite3-adapter', '~> 1.3.9'
    s.add_development_dependency 'jdbc-mysql', '~> 5.1.25'
  else
    s.add_development_dependency 'therubyracer', '~> 0.12.2'

    s.add_development_dependency 'mysql2', '~> 0.3.20'
  end
end
