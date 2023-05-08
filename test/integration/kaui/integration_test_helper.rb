# frozen_string_literal: true

module Kaui
  class IntegrationTestHelper < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    BASE_PATH     = '/kaui'
    TENANTS_PATH  = '/kaui/tenants'
    HOME_PATH     = '/kaui/home'
    SIGN_IN_PATH  = "#{BASE_PATH}/users/sign_in".freeze
    SIGN_OUT_PATH = "#{BASE_PATH}/users/sign_out".freeze
    ACCOUNTS_PATH = "#{BASE_PATH}/accounts".freeze

    include KillbillTestHelper

    # Called before every single test
    setup do
      setup_integration_test
    end

    # Called after every single test
    teardown do
      teardown_integration_test
    end

    protected

    def setup_integration_test
      setup_test_data(1, true)
    end

    def teardown_integration_test; end
  end
end
