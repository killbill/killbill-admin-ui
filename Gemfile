# frozen_string_literal: true

source 'https://rubygems.org'
ruby '>= 3.1.0'

gemspec

gem 'rails', '~> 7.0.1'
group :development do
  gem 'gem-release'
  gem 'json'
  gem 'listen'
  gem 'multi_json'
  gem 'pry-rails'
  gem 'puma'
  gem 'rails-controller-testing'
  gem 'rake'
  gem 'rubocop'
  gem 'simplecov'

  if defined?(JRUBY_VERSION)
    gem 'activerecord-jdbc-adapter', '~> 70.0'
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

# gem 'kenui', :path => '../killbill-email-notifications-ui'
# gem 'kenui', git: 'https://github.com/killbill/killbill-email-notifications-ui.git', branch: 'master'
gem 'kenui'

# gem 'killbill-assets-ui', github: 'killbill/killbill-assets-ui', ref: 'main'
# gem 'killbill-assets-ui', path: '../killbill-assets-ui'
gem 'killbill-assets-ui'

# gem 'killbill-client', path: '../killbill-client-ruby'
# gem 'killbill-client', git: 'https://github.com/killbill/killbill-client-ruby.git', branch: 'master'
gem 'killbill-client'
