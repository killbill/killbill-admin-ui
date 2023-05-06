# frozen_string_literal: true

require 'test_helper'

module Kaui
  class RoleDefinitionsControllerTest < Kaui::FunctionalTestHelper
    test 'should instantiate RoleDefinition class' do
      get :new
      role_definition = assigns(:role_definition)

      assert_not_nil role_definition
      assert_instance_of Kaui::RoleDefinition, role_definition
      assert_response :success
    end

    test 'should return an error if no parameter role definition is passed' do
      post :create

      role_definition = assigns(:role_definition)

      assert_nil role_definition
      assert_equal 'Required parameter missing: role_definition', flash[:error]
      assert_response :redirect
    end

    test 'should create a new role definition' do
      role_definition = {}

      role_definition['role'] = "test#{SecureRandom.base64(9).gsub(%r{[/+=]}, '')}"
      role_definition['permissions'] = 'account:delete_emails,account:add_emails'

      post :create, params: { role_definition: }

      assert_equal 'Role was successfully created', flash[:notice]
      assert_response :redirect
    end

    test 'should return an error if there is a error while creating role' do
      role_definition = {}

      role_definition['role'] = "test#{SecureRandom.base64(9).gsub(%r{[/+=]}, '')}"
      role_definition['permissions'] = 'account:delete_emails,account:add_emails'

      post :create, params: { role_definition:, reason: SecureRandom.base64(4000), comment: SecureRandom.base64(4000) }
      assert_match 'Error while creating role', flash[:error]
      assert_response :success
    end
  end
end
