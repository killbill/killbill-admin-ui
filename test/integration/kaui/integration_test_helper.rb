module Kaui
  class IntegrationTestHelper < ActionDispatch::IntegrationTest

    BASE_PATH    = '/kaui'
    TENANTS_PATH    = '/kaui/tenants'
    HOME_PATH    = '/kaui/home'
    SIGN_IN_PATH = BASE_PATH + '/users/sign_in'
    SIGN_OUT_PATH = BASE_PATH + '/users/sign_out'
    ACCOUNTS_PATH = BASE_PATH + '/accounts'
    ACCOUNT_TIMELINE_PATH = BASE_PATH + '/account_timelines'

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
      setup_test_data
    end

    def teardown_integration_test
    end
  end
end
