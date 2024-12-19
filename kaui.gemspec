# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('lib', __dir__)

require 'kaui/version'

Gem::Specification.new do |s|
  s.name = 'kaui'
  s.version = Kaui::VERSION
  s.summary = 'Killbill Admin UI mountable engine'
  s.description = 'Rails UI plugin for Killbill administration.'

  s.required_ruby_version = '>= 2.7.0'

  s.license = 'Apache License (2.0)'

  s.author = 'Kill Bill core team'
  s.email = 'killbilling-users@googlegroups.com'
  s.homepage = 'https://killbill.io'

  s.files = Dir['{app,config,db,lib}/**/*'] + %w[MIT-LICENSE Rakefile README.md]

  s.metadata['rubygems_mfa_required'] = 'true'

  s.add_dependency 'actionpack'
  s.add_dependency 'cancan'
  s.add_dependency 'concurrent-ruby'
  s.add_dependency 'country_select'
  s.add_dependency 'devise'
  s.add_dependency 'font-awesome-rails'
  s.add_dependency 'jquery-rails', '~> 4.5.1'
  s.add_dependency 'jquery-ui-rails'
  s.add_dependency 'js-routes'
  s.add_dependency 'jwt'
  s.add_dependency 'kenui'
  s.add_dependency 'killbill-assets-ui'
  s.add_dependency 'killbill-client'
  s.add_dependency 'money-rails'
  s.add_dependency 'mustache-js-rails'
  s.add_dependency 'popper_js', '~> 2.11.5'
  s.add_dependency 'rails', '~> 7.0'
  s.add_dependency 'spinjs-rails'
  s.add_dependency 'sprockets'
  s.add_dependency 'sprockets-rails'
  s.add_dependency 'symmetric-encryption'
end
