# frozen_string_literal: true

require 'simplecov'
require 'pry'
SimpleCov.start 'rails'

# Configure the Rails Environment
ENV['RAILS_ENV'] = 'test'

require 'rails-controller-testing'
Rails::Controller::Testing.install

require File.expand_path('dummy/config/environment.rb', __dir__)
require 'rails/test_help'

Rails.backtrace_cleaner.remove_silencers!

require 'multi_json'

# Include helpers
require 'killbill_test_helper'
require 'functional/kaui/functional_test_helper_nosetup'
require 'functional/kaui/functional_test_helper'
require 'integration/kaui/integration_test_helper'
