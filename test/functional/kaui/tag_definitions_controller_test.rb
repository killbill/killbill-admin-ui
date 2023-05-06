# frozen_string_literal: true

require 'test_helper'

module Kaui
  class TagDefinitionsControllerTest < Kaui::FunctionalTestHelper
    test 'should list tag definitions' do
      get :index
      assert_response 200
    end

    test 'should add and destroy tag definition' do
      get :new
      assert_response 200
      assert_not_nil assigns(:tag_definition)

      tag_definition = SecureRandom.uuid[0..5]
      post :create,
           params: {
             tag_definition: {
               name: tag_definition,
               description: SecureRandom.uuid,
               applicable_object_types: { '0' => 'ACCOUNT' }
             }
           }
      assert_redirected_to tag_definitions_path
      assert_equal 'Tag definition successfully created', flash[:notice]

      delete :destroy, params: { id: assigns(:tag_definition).id }
      assert_redirected_to tag_definitions_path
      assert_equal 'Tag definition successfully deleted', flash[:notice]
    end
  end
end
