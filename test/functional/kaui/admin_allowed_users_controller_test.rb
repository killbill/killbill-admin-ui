require 'test_helper'

module Kaui
  class AdminAllowedUsersControllerTest < Kaui::FunctionalTestHelper
    test "should get new" do
      post :new
      assert_response :success
    end

    test "should get create" do
      post :create, :allowed_user => { :kb_username => 'Albator', :description => 'My french super hero'}
      assert_response 302
    end

    test 'should get index' do
      get :index
      assert_response 200
    end


    test "should get show" do
      au = Kaui::AllowedUser.new
      au.kb_username = 'Mad Max'
      au.description = 'My super hero'
      au.save!
      get :show, :id => au.id
      assert_response :success
    end
  end
end
