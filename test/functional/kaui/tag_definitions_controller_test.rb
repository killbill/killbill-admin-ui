require 'test_helper'

class Kaui::TagDefinitionsControllerTest < Kaui::FunctionalTestHelper

  test 'should list tag definitions' do
    get :index
    assert_response 200
  end

  test 'should show tag definition' do
    get :show, :id => '00000000-0000-0000-0000-000000000001'
    assert_response 200
    assert_equal 'AUTO_PAY_OFF', assigns(:tag_definition).name
  end

  test 'should add and destroy tag definition' do
    get :new
    assert_response 200
    assert_not_nil assigns(:tag_definition)

    tag_definition = SecureRandom.uuid[0..5]
    post :create,
         :tag_definition => {
             :name        => tag_definition,
             :description => SecureRandom.uuid
         }
    assert_redirected_to tag_definition_path(assigns(:tag_definition).id)
    assert_equal 'Tag definition successfully created', flash[:notice]

    delete :destroy, :id => assigns(:tag_definition).id
    assert_redirected_to tag_definitions_path
    assert_equal 'Tag definition successfully deleted', flash[:notice]
  end
end
