source 'http://rubygems.org'

gemspec

if defined?(JRUBY_VERSION)
  group :development do
    # See https://github.com/jruby/activerecord-jdbc-adapter/issues/700
    github 'jruby/activerecord-jdbc-adapter', branch: 'rails-5' do
      gem 'activerecord-jdbc-adapter'
      gem 'activerecord-jdbcmysql-adapter'
      gem 'activerecord-jdbcpostgresql-adapter'
      gem 'activerecord-jdbcsqlite3-adapter'
      gem 'jdbc-mysql'
    end
  end
end

#gem 'killbill-client', :path => '../killbill-client-ruby'
#gem 'killbill-client', :git => 'https://github.com/killbill/killbill-client-ruby.git'
