require 'test_helper'

module Kaui
  class TagDefinitionsControllerTest < ActionController::TestCase
    fixtures :tag_definitions

    setup do
      @tag_definition = TagDefinition.new(tag_definitions(:payment_plan))
      @routes = Kaui::Engine.routes
    end

    test "should get index" do
      get :index, :use_route => 'kaui'
      assert_response :success
      assert_not_nil assigns(:tag_definitions)
    end

    test "should get new" do
      get :new, :use_route => 'kaui'
      assert_response :success
    end

    test "should create tag_definition" do
      assert_difference('TagDefinition.count') do
        post :create, :tag_definition => { :description => @tag_definition.description, :name => @tag_definition.name }
      end

      # TODO - for now, we redirect to the main page as we don't get the id back
      assert_redirected_to tag_definitions_path
      # assert_redirected_to tag_definition_path(assigns(:tag_definition))
    end

    test "should show tag_definition" do
      get :show, :id => @tag_definition, :use_route => 'kaui'
      assert_response :success
    end

    test "should get edit" do
      get :edit, :id => @tag_definition, :use_route => 'kaui'
      assert_response :success
    end

    # TODO - not supported yet
    # test "should update tag_definition" do
    #   put :update, id: @tag_definition, tag_definition: { description: @tag_definition.description, id: @tag_definition.id, name: @tag_definition.name }
    #   assert_redirected_to tag_definition_path(assigns(:tag_definition))
    # end

    test "should destroy tag_definition" do
      post :create, :tag_definition => { :description => @tag_definition.description, :name => @tag_definition.name }
      new_id = assigns(:tag_definition).id

      assert_difference('TagDefinition.count', -1) do
        delete :destroy, :id => new_id
      end

      assert_redirected_to tag_definitions_path
    end
  end
end
