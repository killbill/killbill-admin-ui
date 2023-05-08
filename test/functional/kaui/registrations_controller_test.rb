# frozen_string_literal: true

require 'test_helper'

module Kaui
  class RegistrationsControllerTest < Kaui::FunctionalTestHelper
    test 'should get new' do
      logout

      get :new
      assert_response :success
      assert input_field?('user_kb_username'), 'Expected input with id user_kb_username not found'
      assert input_field?('user_password'), 'Expected input with id user_password not found'
    end

    test 'should get create' do
      logout

      # enable the option of registration
      Kaui.disable_sign_up_link = false

      parameters = {
        user: {
          kb_username: 'Voltron',
          password: 'Voltron'
        }
      }
      post :create, params: parameters
      assert_equal "User #{parameters[:user][:kb_username]} successfully created, please login", flash[:notice]
      assert_response :redirect
      # validate redirect path
      assert response_path.include?('/users/sign_in'), "#{response_path} is expected to contain /users/sign_in"

      # should return an error that the user already exists
      post :create, params: parameters
      assert_equal "User with name #{parameters[:user][:kb_username]} already exists!", flash[:error]
      assert_response :success

      # disable the option of registration
      Kaui.disable_sign_up_link = true

      post :create, params: parameters
      assert_equal 'You need to sign in before adding a user!', flash[:error]
      assert_response :redirect
      # validate redirect path
      assert response_path.include?('/users/sign_in'), "#{response_path} is expected to contain /users/sign_in"
    end
  end
end
