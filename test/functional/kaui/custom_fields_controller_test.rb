require 'test_helper'

class Kaui::CustomFieldsControllerTest < Kaui::FunctionalTestHelper

  test 'should get index' do
    get :index
    assert_response 200
  end

  test 'should list custom fields' do
    # Test pagination
    get :pagination, :format => :json
    verify_pagination_results!
  end

  test 'should search custom fields' do
    # Test search
    get :pagination, :sSearch => 'foo', :format => :json
    verify_pagination_results!
  end
end
