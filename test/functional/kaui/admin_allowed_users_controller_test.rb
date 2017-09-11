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

      # validate redirect path
      id = get_allowed_id @response.body
      assert_equal "/kaui/admin_allowed_users/#{id}", URI(@response.get_header('Location')).path
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

      # validate redirect path
      id = get_allowed_id @response.body
      assert_equal "/kaui/admin_allowed_users/#{id}", URI(@response.get_header('Location')).path

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

      allowed_username = get_allowed_username @response.body
      assert_equal allowed_username, au.kb_username
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

      # validate redirect path
      id = get_allowed_id @response.body
      assert_equal "/kaui/admin_allowed_users/#{id}", URI(@response.get_header('Location')).path


      parameters = {
          :id => id,
          :allowed_user => { :description => 'An post-apocalyptic super hero' },
          :roles => 'one,two'
      }

      put :update, parameters
      assert_equal 'User was successfully updated', flash[:notice]
      assert_response :redirect
      # validate redirect path
      assert_equal "/kaui/admin_allowed_users/#{id}", URI(@response.get_header('Location')).path

      # get the user to verify that the data was actually updated
      get :edit, :id => id
      description = get_allowed_description @response.body
      assert_response :success
      assert_equal parameters[:allowed_user][:description], description

      # delete created user
      delete :destroy, :id => id
      assert_equal 'User was successfully deleted', flash[:notice]
      assert_response :redirect
      # validate redirect path
      assert_equal '/kaui/admin_allowed_users', URI(@response.get_header('Location')).path
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
      id = get_allowed_id @response.body
      # validate redirect path
      assert_equal "/kaui/admin_allowed_users/#{id}", URI(@response.get_header('Location')).path

      delete :destroy, :id => id
      assert_equal 'User was successfully deleted', flash[:notice]
      assert_response :redirect
      # validate redirect path
      assert_equal '/kaui/admin_allowed_users', URI(@response.get_header('Location')).path

      # should respond with an error if tried to delete again
      delete :destroy, :id => id
      assert_equal "Error: Couldn't find Kaui::AllowedUser with 'id'=#{id}", flash[:error]
      assert_response :redirect
      # validate redirect path
      assert_equal '/kaui/home', URI(@response.get_header('Location')).path
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
      # validate redirect path
      assert_equal "/kaui/admin_allowed_users/#{au.id}", URI(@response.get_header('Location')).path
    end

    private

      def get_allowed_username(response_body)
        fields = /<input.*type="text".*value="(?<value>.+)".*name=.allowed_user.kb_username...*>/.match(response_body)

        fields[:value]
      end

      def get_allowed_description(response_body)
        fields = /<input.*type="text".*value="(?<value>.+)".*name=.allowed_user.description...*>/.match(response_body)

        fields[:value]
      end

      def get_allowed_id(response_body)
        fields = /<form.*action="\/.*\/.*\/(?<id>.*)".accept-charset=.*method="post">/.match(response_body)
        fields = /<a.href="http:\/.*\/.*\/(?<id>.*)">/.match(response_body) if fields.nil?

        return nil if fields.nil?
        fields[:id]
      end
  end
end
