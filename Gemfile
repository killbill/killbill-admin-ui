source "http://rubygems.org"

gem "rails", "~> 3.2.3"
gem 'rest-client', '~> 1.6.7'
gem 'money-rails', '~> 0.5.0'
gem 'd3_rails', '~> 2.10.0'

group :development, :test do
  # jquery-rails is used by the dummy application
  gem "jquery-rails"

  if defined?(JRUBY_VERSION)
    gem "jruby-openssl", "~> 0.7.7"

    gem 'activerecord-jdbc-adapter', '~> 1.2.2'
    gem 'activerecord-jdbcmysql-adapter', '~> 1.2.2'
    gem 'jdbc-mysql', :require => false
  else
    gem 'mysql2'
  end
end
