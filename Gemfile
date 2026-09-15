# frozen_string_literal: true

source 'https://rubygems.org'
ruby '>= 3.1.0'

gemspec

gem 'rails', '~> 7.2.0'

# Lock i18n to 1.14.x for: https://github.com/ruby-i18n/i18n/issues/735
gem 'i18n', '~> 1.14.0'

# Lock minitest to 5.x until Rails 7.1+ adds Minitest 6.0 support
# Minitest 6.0.0 was released Dec 2024 with breaking API changes
gem 'minitest', '~> 5.0'

# json 3.0 dropped the quirks_mode keyword that ActiveSupport::JSON.encode
# still passes to JSON.generate, raising ArgumentError (breaks any code path
# that calls #to_json, e.g. killbill-client's model classes). This repo's
# rubocop ~> 1.89.0 pin below happens to also constrain json < 3 (rubocop
# 1.89.0 depends on json ~> 2.3), but rubocop 1.90.0 loosened that to
# json >= 2.3 (no upper bound) - pin json explicitly so this doesn't depend
# on the rubocop pin never changing.
gem 'json', '~> 2.21'

group :development do
  gem 'gem-release'
  gem 'listen'
  gem 'multi_json'
  gem 'pry-rails'
  gem 'puma'
  gem 'rails-controller-testing'
  gem 'rake'
  gem 'simplecov'

  if defined?(JRUBY_VERSION)
    gem 'activerecord-jdbc-adapter', '~> 72.0'
    # Add the drivers
    gem 'jdbc-mariadb'
    gem 'jdbc-postgres'
    gem 'jdbc-sqlite3'
  else
    gem 'byebug'
    gem 'flamegraph'
    gem 'mysql2'
    gem 'pg'
    gem 'rack-mini-profiler'
    gem 'stackprof'
  end
end

group :development, :test do
  gem 'rubocop', '~> 1.89.0', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rails', '~> 2.36.0', require: false
  gem 'rubocop-rspec', '~> 3.10.2', require: false
  gem 'rubocop-thread_safety', require: false
end

# gem 'killbill-assets-ui', github: 'killbill/killbill-assets-ui', ref: 'main'
# gem 'killbill-assets-ui', path: '../killbill-assets-ui'
gem 'killbill-assets-ui'

# gem 'killbill-client', path: '../killbill-client-ruby'
# gem 'killbill-client', git: 'https://github.com/killbill/killbill-client-ruby.git', branch: 'kaui_6.17'
gem 'killbill-client'
