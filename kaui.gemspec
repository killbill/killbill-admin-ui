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
  s.add_dependency 'js-routes'
  s.add_dependency 'jquery-rails'
  s.add_dependency 'jquery-datatables-rails'
  s.add_dependency 'money-rails'
  # See https://github.com/seyhunak/twitter-bootstrap-rails/issues/897
  s.add_dependency 'bootstrap'
  s.add_dependency 'bootstrap-sass'
  s.add_dependency 'font-awesome-rails'
  s.add_dependency 'bootstrap-datepicker-rails'
  s.add_dependency 'killbill-client'
  s.add_dependency 'devise'
  s.add_dependency 'cancan'
  s.add_dependency 'country_select'
  s.add_dependency 'symmetric-encryption'
  s.add_dependency 'jwt'
  s.add_dependency 'sprockets'
  s.add_dependency 'kenui'
  s.add_dependency 'jquery-ui-rails'
  s.add_dependency 'sass'
  s.add_dependency 'sass-rails'
  s.add_dependency 'concurrent-ruby'
  s.add_dependency 'sprockets-rails'
  s.add_dependency 'mustache-js-rails'
  s.add_dependency 'actionpack'
  s.add_dependency 'awesome_print'
  s.add_dependency 'bootsnap'
  s.add_dependency 'mysql2'
  s.add_dependency 'pg'


  s.add_development_dependency 'rails-controller-testing'
  s.add_development_dependency 'multi_json'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'pry-rails'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'json'
  s.add_development_dependency 'listen'
  s.add_development_dependency 'puma'
  s.add_development_dependency 'gem-release'
  s.add_development_dependency 'mysql2'
  s.add_development_dependency 'pg'
  s.add_development_dependency 'awesome_print'
  s.add_development_dependency 'rack-mini-profiler'
  s.add_development_dependency 'flamegraph'
  s.add_development_dependency 'stackprof'
end
