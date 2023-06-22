# frozen_string_literal: true

source 'https://rubygems.org'
ruby '>= 3.1.0'

gemspec

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
    git 'https://github.com/jruby/activerecord-jdbc-adapter', branch: 'master' do
      gem 'activerecord-jdbc-adapter'
      # Add the drivers
      gem 'jdbc-mariadb'
      gem 'jdbc-postgres'
      gem 'jdbc-sqlite3'
    end
  else
    gem 'byebug'
    gem 'flamegraph'
    gem 'mysql2'
    gem 'pg'
    gem 'rack-mini-profiler'
    gem 'stackprof'
  end
end

# gem 'killbill-client', :path => '../killbill-client-ruby'
# gem 'killbill-client', :git => 'https://github.com/killbill/killbill-client-ruby.git', :branch => 'work-for-release-0.21.x'
# gem 'killbill-client', '3.2.0'

# gem 'kenui', :path => '../killbill-email-notifications-ui'
gem 'kenui', git: 'https://github.com/killbill/killbill-email-notifications-ui.git', branch: 'master'
