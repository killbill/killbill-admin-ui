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

    test 'should list role definitions' do
      roles = [Kaui::RoleDefinition.new(role: 'b_role', permissions: ['invoice:view']),
               Kaui::RoleDefinition.new(role: 'a_role', permissions: %w[account:create account:update])]

      Kaui::RoleDefinition.stub(:find_all, roles) do
        get :index
      end

      assert_response :success
      assert_equal %w[a_role b_role], assigns(:role_definitions).map(&:role)
      assert_nil assigns(:list_unsupported)
    end

    test 'should link to the edit page of each listed role' do
      roles = [Kaui::RoleDefinition.new(role: 'finance', permissions: ['invoice:view'])]

      Kaui::RoleDefinition.stub(:find_all, roles) do
        get :index
      end

      assert_select "a[href='#{edit_role_definition_path('finance')}']"
      assert_select 'td', text: 'invoice:view'
    end

    test 'should handle servers that cannot list role definitions' do
      unsupported = ->(*) { raise KillBillClient::API::ClientError.new(nil, Struct.new(:code, :body).new('405', '')) }
      Kaui::RoleDefinition.stub(:find_all, unsupported) do
        get :index
      end

      assert_response :success
      assert_empty assigns(:role_definitions)
      assert assigns(:list_unsupported)
    end

    test 'should edit and update a role definition' do
      role_name = "test#{SecureRandom.base64(9).gsub(%r{[/+=]}, '')}"
      post :create, params: { role_definition: { role: role_name, permissions: 'account:delete_emails' } }
      assert_equal 'Role was successfully created', flash[:notice]

      get :edit, params: { id: role_name }
      assert_response :success
      assert_equal role_name, assigns(:role_definition).role
      assert_equal 'account:delete_emails', assigns(:role_definition).permissions

      assert_select "input#role_definition_role[readonly][value='#{role_name}']"
      assert_select 'form input[name=_method][value=put]'
      assert_select 'button[type=submit]', text: /Update Role/

      put :update, params: { id: role_name, role_definition: { role: role_name, permissions: 'account:delete_emails,account:add_emails' } }
      assert_redirected_to role_definitions_path
      assert_equal "Role '#{role_name}' was successfully updated", flash[:notice]

      get :edit, params: { id: role_name }
      # Kill Bill does not preserve the order of the permissions
      assert_equal %w[account:add_emails account:delete_emails], assigns(:role_definition).permissions.split(',').sort
    end

    test 'should redirect to the roles list when the role does not exist' do
      get :edit, params: { id: "missing#{SecureRandom.hex(4)}" }

      assert_redirected_to role_definitions_path
      assert_match 'was not found', flash[:error]
    end
  end
end
