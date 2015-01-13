require 'test_helper'

module Kaui
  class TenantsControllerTest < ActionController::TestCase
    test "should get index" do
      get :index, :use_route => 'kaui'
      assert_response :success
    end
  end
end
