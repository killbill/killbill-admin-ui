require 'simplecov'
SimpleCov.start 'rails'

# Configure the Rails Environment
ENV['RAILS_ENV'] = 'test'

require File.expand_path('../dummy/config/environment.rb', __FILE__)
require 'rails/test_help'

Rails.backtrace_cleaner.remove_silencers!

# Include helpers
require 'killbill_test_helper'
require 'functional/kaui/functional_test_helper_nosetup'
require 'functional/kaui/functional_test_helper'
require 'integration/kaui/integration_test_helper'
