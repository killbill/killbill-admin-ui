require 'test_helper'

module Kaui
  class TenantsControllerTest < ActionController::TestCase
    test "should get index" do
      get :index
      assert_response :success
    end
  end
end
