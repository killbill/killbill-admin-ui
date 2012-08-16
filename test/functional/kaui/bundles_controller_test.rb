require 'test_helper'

class Kaui::BundlesControllerTest < ActionController::TestCase
  fixtures :accounts, :bundles

  test "should get index" do
    get :index
    assert_response :success
  end

  test "should find bundle by id" do
    pierre = accounts(:pierre)
    bundle = bundles(:bundle_for_pierre)

    get :show, :id => bundle["bundleId"]
    assert_response :success
    assert_equal assigns(:account).account_id, pierre["accountId"]
    assert_equal assigns(:bundle).bundle_id, bundle["bundleId"]
    assert_equal assigns(:bundle).account_id, pierre["accountId"]
  end
end