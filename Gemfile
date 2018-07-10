source 'http://rubygems.org'

gemspec

if defined?(JRUBY_VERSION)
  group :development do
    # Releases for Rails 5.1 aren't available yet
    github 'jruby/activerecord-jdbc-adapter', ref: '54c94fd4fe74648acc6590841a2f3e59652f85a8' do
      # Pulls activerecord-jdbc-adapter and jdbc-mysql
      gem 'activerecord-jdbcmysql-adapter'
      # Add MariaDB driver as well
      gem 'jdbc-mariadb'
      # Pulls activerecord-jdbc-adapter and jdbc-postgres
      gem 'activerecord-jdbcpostgresql-adapter'
      # Pulls activerecord-jdbc-adapter and jdbc-sqlite3
      gem 'activerecord-jdbcsqlite3-adapter'
    end
  end
end

#gem 'killbill-client', :path => '../killbill-client-ruby'
gem 'killbill-client', :git => 'https://github.com/killbill/killbill-client-ruby.git', :branch => 'master'

#gem 'kenui', :path => '../killbill-email-notifications-ui'
#gem 'kenui', :git => 'https://github.com/killbill/killbill-email-notifications-ui.git', :branch => 'master'
