require 'test_helper'

class Kaui::TenantsControllerTest < Kaui::FunctionalTestHelper

  test "should get index" do
    get :index, :use_route => 'kaui'
    assert_response :success
  end
end
