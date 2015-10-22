require 'test_helper'

class Kaui::TenantsControllerTest < Kaui::FunctionalTestHelperNoSetup

  setup do
    # Do nothing and let the test initialize with correct # tenants
  end

  teardown do
    # Do nothing and let the test initialize with correct # tenants
  end

  #
  # We don't configure the tenants in 'kaui_tenants' and don't set KillBillClient.api_key
  #
  test 'should get index with 0 tenant with NO KillBillClient.api_key set' do
    setup_functional_test(0, false)
    get :index, :use_route => 'kaui'
    # Sign-up flow
    assert_redirected_to new_admin_tenant_path
  end

  #
  # We don't configure the tenants in 'kaui_tenants' but we set KillBillClient.api_key (default use case for non multi-tenant UI)
  #
  test 'should get index with 0 tenant with KillBillClient.api_key set' do
    setup_functional_test(0)
    get :index, :use_route => 'kaui'
    assert_response 302
    assert_redirected_to Kaui::IntegrationTestHelper::HOME_PATH
    assert_equal 'Signed in successfully.', flash[:notice]
  end

  #
  # We configure 1 tenant in 'kaui_tenants' (the one we created with Kill Bill) and verify we skip the tenant screen
  #
  test 'should get index with 1 tenant' do
    setup_functional_test(1)
    get :index, :use_route => 'kaui'
    assert_includes (200..399), response.code.to_i
    assert_equal 'Signed in successfully.', flash[:notice]
  end

  #
  # We configure 2 tenants in 'kaui_tenants' (the one we created with Kill Bill and another one) and verify we land on the view for the
  # user to chose his tenant.
  #
  test 'should get index with 2 tenant' do
    setup_functional_test(2)
    get :index, :use_route => 'kaui'
    assert_response :success
    assert_equal 'Signed in successfully.', flash[:notice]
  end
end
