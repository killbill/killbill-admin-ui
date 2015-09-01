require 'test_helper'

class Kaui::TagsControllerTest < Kaui::FunctionalTestHelper

  test 'should get index' do
    get :index
    assert_response 200
  end

  test 'should list tags' do
    # Test pagination
    get :pagination, :format => :json
    verify_pagination_results!
  end

  test 'should search tags' do
    # Test search
    get :pagination, :search => {:search => 'foo'}, :format => :json
    verify_pagination_results!
  end
end
