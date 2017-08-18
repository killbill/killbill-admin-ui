source 'http://rubygems.org'

gemspec

if defined?(JRUBY_VERSION)
  group :development do
    # See https://github.com/jruby/activerecord-jdbc-adapter/issues/700
    github 'jruby/activerecord-jdbc-adapter', branch: 'rails-5' do
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
#gem 'killbill-client', :git => 'https://github.com/killbill/killbill-client-ruby.git'
