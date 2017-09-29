require 'test_helper'

module Kaui
  class RegistrationsControllerTest < Kaui::FunctionalTestHelper

    test 'should get new' do
      logout

      get :new
      assert_response :success
      assert has_input_field('user_kb_username'), 'Expected input with id user_kb_username not found'
      assert has_input_field('user_password'), 'Expected input with id user_password not found'
    end

    test 'should get create' do
      logout

      parameters = {
        :user => {
          :kb_username => 'Voltron',
          :password => 'Voltron'
        }
      }
      post :create, parameters
      assert_equal "User #{parameters[:user][:kb_username]} successfully created, please login", flash[:notice]
      assert_response :redirect
      # validate redirect path
      assert response_path.include?('/users/sign_in'), "#{response_path} is expected to contain /users/sign_in"

      # should return an error that the user already exists
      post :create, parameters
      assert_equal "User with name #{parameters[:user][:kb_username]} already exists!", flash[:error]
      assert_response :success
    end

  end
end