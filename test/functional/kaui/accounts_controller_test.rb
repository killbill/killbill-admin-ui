require 'test_helper'

class Kaui::AccountsControllerTest < ActionController::TestCase
  fixtures :accounts

  test "should get index" do
    get :index
    assert_response :success
  end

  test "should find account by id" do
    pierre = accounts(:pierre)

    get :show, :id => pierre["accountId"]
    assert_response :success
    assert_equal assigns(:account).account_id, pierre["accountId"]
  end
end