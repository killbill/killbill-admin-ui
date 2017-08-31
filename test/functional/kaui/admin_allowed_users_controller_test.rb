require 'test_helper'

module Kaui
  class AdminAllowedUsersControllerTest < Kaui::FunctionalTestHelper

    test 'should get new' do
      post :new
      assert_response :success
    end

    test 'should get create local only' do
      parameters = {
          :allowed_user => {:kb_username => 'Albator', :description => 'My french super hero'},
          :password => 'Albator',
          :roles => nil,
          :external => '1'
      }
      post :create, parameters
      assert_equal 'User was successfully configured', flash[:notice]
      assert_response 302
    end

    test 'should get create' do
      parameters = {
          :allowed_user => {:kb_username => 'Albator', :description => 'My french super hero'},
          :password => 'Albator',
          :roles => nil
      }
      post :create, parameters
      assert_equal 'User was successfully configured', flash[:notice]
      assert_response 302
      allowed_user = assigns(:allowed_user)

      # should return an error that the user already exists
      post :create, parameters
      assert_equal "User with name #{parameters[:allowed_user][:kb_username]} already exists!", flash[:error]
      assert_response :success
    end

    test 'should get index' do
      get :index
      assert_response 200
    end

    test 'should get show' do
      au = Kaui::AllowedUser.new
      au.kb_username = 'Mad Max'
      au.description = 'My super hero'
      au.save!

      get :show, :id => au.id
      assert_response :success
    end

    test 'should get edit' do
      au = Kaui::AllowedUser.new
      au.kb_username = 'Mad Max'
      au.description = 'My super hero'
      au.save!

      get :edit, :id => au.id

      allowed_user = assigns(:allowed_user)
      assert_equal allowed_user.kb_username, au.kb_username
      assert_response :success
    end

    test 'should update allowed user' do
      parameters = {
          :allowed_user => {:kb_username => 'Mad Max', :description => 'My super hero'},
          :password => 'Batman',
          :roles => nil
      }
      post :create, parameters
      assert_equal 'User was successfully configured', flash[:notice]
      assert_response :redirect

      au = assigns(:allowed_user)
      parameters = {
          :id => au.id,
          :allowed_user => { :description => 'An post-apocalyptic super hero' },
          :roles => 'one,two'
      }

      put :update, parameters

      allowed_user = assigns(:allowed_user)
      assert_equal parameters[:allowed_user][:description], allowed_user.description
      assert_equal 'User was successfully updated', flash[:notice]
      assert_response :redirect

      # delete created user
      delete :destroy, :id => au.id
      assert_equal 'User was successfully deleted', flash[:notice]
      assert_response :redirect
    end

    test 'should delete allowed user' do
      parameters = {
          :allowed_user => {:kb_username => 'Batman', :description => 'Everyone wants to be batman'},
          :password => 'Batman',
          :roles => nil
      }
      post :create, parameters
      assert_equal 'User was successfully configured', flash[:notice]
      assert_response :redirect
      au = assigns(:allowed_user)

      delete :destroy, :id => au.id
      assert_equal 'User was successfully deleted', flash[:notice]
      assert_response :redirect

      # should respond with an error if tried to delete again
      delete :destroy, :id => au.id
      assert_equal "Error: Couldn't find Kaui::AllowedUser with 'id'=#{au.id}", flash[:error]
      assert_response :redirect
    end

    test 'should add tenant' do
      allowed_user = {:kb_username => 'Mad Max', :description => 'My super hero'}

      au = Kaui::AllowedUser.new
      au.kb_username = allowed_user[:kb_username]
      au.description = allowed_user[:description]
      au.save!

      allowed_user[:id] = au.id

      put :add_tenant, :allowed_user => allowed_user, :tenant_1 => nil
      assert_equal 'Successfully set tenants for user', flash[:notice]
      assert_response :redirect
    end
  end
end
