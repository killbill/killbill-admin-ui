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

  s.files = Dir['{app,config,db,lib}/**/*'] + %w(MIT-LICENSE Rakefile README.md)
  s.test_files = Dir['test/**/*']

  s.add_dependency 'rails', '~> 5.2.8.1'
  s.add_dependency 'js-routes', '~> 2.2.4'
  s.add_dependency 'jquery-rails', '~> 4.5.0'
  s.add_dependency 'jquery-datatables-rails', '~> 3.4.0'
  s.add_dependency 'money-rails', '~> 1.15.0'
  s.add_dependency 'bootstrap', '~> 5.2.2'
  s.add_dependency 'bootstrap-sass', '~> 3.4.1'
  s.add_dependency 'font-awesome-rails', '~> 4.7.0.8'
  s.add_dependency 'bootstrap-datepicker-rails', '~> 1.9.0.1'
  s.add_dependency 'killbill-client', '~> 3.3.1'
  s.add_dependency 'devise', '~> 4.8.1'
  s.add_dependency 'cancan', '~> 1.6.10'
  s.add_dependency 'country_select', '~> 6.1.1'
  s.add_dependency 'symmetric-encryption', '~> 4.6.0'
  s.add_dependency 'jwt', '~> 2.5.0'
  s.add_dependency 'sprockets', '~> 4.1.1'
  s.add_dependency 'kenui', '~> 2.0.2'
  s.add_dependency 'jquery-ui-rails', '~> 6.0.1'
  s.add_dependency 'sass', '~> 3.7.4'
  s.add_dependency 'sass-rails', '~> 6.0.0'
  s.add_dependency 'concurrent-ruby', '~> 1.1.10'
  s.add_dependency 'sprockets-rails', '~> 3.4.2'
  s.add_dependency 'mustache-js-rails', '~> 4.1.0.3'
  s.add_dependency 'actionpack', '~> 5.2.8.1'
  s.add_dependency 'bootsnap', '~> 1.13.0'
  s.add_dependency 'mysql2', '~> 0.5.4'
  s.add_dependency 'pg', '~> 1.4.4'
  s.add_dependency 'font-awesome-sass', '~> 6.2.0'

  s.add_development_dependency 'rails-controller-testing', '~> 1.0.5'
  s.add_development_dependency 'multi_json', '~> 1.15.0'
  s.add_development_dependency 'rake', '~> 13.0.6'
  s.add_development_dependency 'pry-rails', '~> 0.3.9'
  s.add_development_dependency 'simplecov', '~> 0.21.2'
  s.add_development_dependency 'json', '~> 2.6.2'
  s.add_development_dependency 'listen', '~> 3.7.1'
  s.add_development_dependency 'puma', '~> 6.0.0'
  s.add_development_dependency 'gem-release', '~> 2.2.2'
  s.add_development_dependency 'rack-mini-profiler', '~> 3.0.0'
  s.add_development_dependency 'flamegraph', '~> 0.9.5'
  s.add_development_dependency 'stackprof', '~> 0.2.22'

end
