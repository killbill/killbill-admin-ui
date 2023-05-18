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
      # Pulls activerecord-jdbc-adapter and jdbc-mysql
      gem 'activerecord-jdbcmysql-adapter'
      # Add MariaDB driver as well
      gem 'jdbc-mariadb'
      # Pulls activerecord-jdbc-adapter and jdbc-postgres
      gem 'activerecord-jdbcpostgresql-adapter'
      # Pulls activerecord-jdbc-adapter and jdbc-sqlite3
      gem 'activerecord-jdbcsqlite3-adapter'
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
