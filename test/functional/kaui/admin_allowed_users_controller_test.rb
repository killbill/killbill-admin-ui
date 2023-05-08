# frozen_string_literal: true

require 'test_helper'

module Kaui
  class AdminAllowedUsersControllerTest < Kaui::FunctionalTestHelper
    test 'should get new' do
      post :new
      assert_response :success
    end

    test 'should get create local only' do
      parameters = {
        allowed_user: { kb_username: SecureRandom.uuid.to_s, description: SecureRandom.uuid.to_s },
        external: '1',
        password: SecureRandom.uuid.to_s,
        roles: nil
      }
      post :create, params: parameters
      assert_equal 'User was successfully configured', flash[:notice]
      assert_response 302

      # validate redirect path
      id = extract_allowed_id(@response.body)
      assert response_path.include?(expected_response_path(id)), "#{response_path} is expected to contain #{expected_response_path(id)}"
    end

    test 'should get create' do
      parameters = {
        allowed_user: { kb_username: SecureRandom.uuid.to_s, description: SecureRandom.uuid.to_s },
        password: SecureRandom.uuid.to_s,
        roles: nil
      }
      post :create, params: parameters
      assert_equal 'User was successfully configured', flash[:notice]
      assert_response 302

      # validate redirect path
      id = extract_allowed_id(@response.body)
      assert response_path.include?(expected_response_path(id)), "#{response_path} is expected to contain #{expected_response_path(id)}"

      # should return an error that the user already exists
      post :create, params: parameters
      assert_equal "User with name #{parameters[:allowed_user][:kb_username]} already exists!", flash[:error]
      assert_response :success
    end

    test 'should get index' do
      get :index
      assert_response 200
    end

    test 'should get show' do
      au = Kaui::AllowedUser.new
      au.kb_username = SecureRandom.uuid.to_s
      au.description = SecureRandom.uuid.to_s
      au.save!

      get :show, params: { id: au.id }
      assert_response :success
    end

    test 'should get edit' do
      au = Kaui::AllowedUser.new
      au.kb_username = SecureRandom.uuid.to_s
      au.description = SecureRandom.uuid.to_s
      au.save!

      get :edit, params: { id: au.id }

      allowed_username = extract_allowed_username
      assert_equal allowed_username, au.kb_username
      assert_response :success
    end

    test 'should update allowed user' do
      parameters = {
        allowed_user: { kb_username: SecureRandom.uuid.to_s, description: SecureRandom.uuid.to_s },
        password: SecureRandom.uuid.to_s,
        roles: nil
      }
      post :create, params: parameters
      assert_equal 'User was successfully configured', flash[:notice]
      assert_response :redirect

      # validate redirect path
      id = extract_allowed_id(@response.body)
      assert response_path.include?(expected_response_path(id)), "#{response_path} is expected to contain #{expected_response_path(id)}"

      parameters = {
        id:,
        allowed_user: { description: 'An post-apocalyptic super hero' },
        roles: 'one,two'
      }

      put :update, params: parameters
      assert_equal 'User was successfully updated', flash[:notice]
      assert_response :redirect
      # validate redirect path
      assert response_path.include?(expected_response_path(id)), "#{response_path} is expected to contain #{expected_response_path(id)}"

      # get the user to verify that the data was actually updated
      get :edit, params: { id: }
      description = extract_allowed_description
      assert_response :success
      assert_equal parameters[:allowed_user][:description], description

      # delete created user
      delete :destroy, params: { id: }
      assert_equal 'User was successfully deleted', flash[:notice]
      assert_response :redirect
      # validate redirect path
      assert response_path.include?(expected_response_path), "#{response_path} is expected to contain #{expected_response_path}"
    end

    test 'should delete allowed user' do
      parameters = {
        allowed_user: { kb_username: SecureRandom.uuid.to_s, description: SecureRandom.uuid.to_s },
        password: SecureRandom.uuid.to_s,
        roles: nil
      }
      post :create, params: parameters
      assert_equal 'User was successfully configured', flash[:notice]
      assert_response :redirect
      id = extract_allowed_id(@response.body)
      # validate redirect path
      assert response_path.include?(expected_response_path(id)), "#{response_path} is expected to contain #{expected_response_path(id)}"

      delete :destroy, params: { id: }
      assert_equal 'User was successfully deleted', flash[:notice]
      assert_response :redirect
      # validate redirect path
      assert response_path.include?(expected_response_path), "#{response_path} is expected to contain #{expected_response_path}"

      # should respond with an error if tried to delete again
      delete :destroy, params: { id: }
      assert_equal "Error: Couldn't find Kaui::AllowedUser with 'id'=#{id}", flash[:error]
      assert_response :redirect
      # validate redirect path
      assert response_path.include?('/kaui/home'), "#{response_path} is expected to contain '/kaui/home'"
    end

    # rubocop:disable Naming/VariableNumber
    test 'should add tenant' do
      allowed_user = { kb_username: SecureRandom.uuid.to_s, description: SecureRandom.uuid.to_s }

      au = Kaui::AllowedUser.new
      au.kb_username = allowed_user[:kb_username]
      au.description = allowed_user[:description]
      au.save!

      allowed_user[:id] = au.id

      put :add_tenant, params: { allowed_user:, tenant_1: nil }
      assert_equal 'Successfully set tenants for user', flash[:notice]
      assert_response :redirect
      # validate redirect path
      assert response_path.include?(expected_response_path(au.id)), "#{response_path} is expected to contain #{expected_response_path(au.id)}"
    end
    # rubocop:enable Naming/VariableNumber

    test 'should detect if a user is managed externally' do
      allowed_user = { kb_username: SecureRandom.uuid.to_s, description: SecureRandom.uuid.to_s }

      # adding only locally will make the user managed externally
      au = Kaui::AllowedUser.new
      au.kb_username = allowed_user[:kb_username]
      au.description = allowed_user[:description]
      au.save!

      # edit the added user and validate that the checkbox of managed externally is disabled
      get :edit, params: { id: au.id }
      assert_response :success
      assert_select 'form input#external' do |checkbox|
        assert_equal checkbox[0]['disabled'], 'disabled'
      end

      # create a user that is managed externally
      parameters = {
        allowed_user: { kb_username: SecureRandom.uuid.to_s, description: SecureRandom.uuid.to_s },
        external: '1'
      }
      post :create, params: parameters
      assert_equal 'User was successfully configured', flash[:notice]
      assert_response 302
      added_au_id = response_path.gsub('/kaui/admin_allowed_users/', '')

      # edit the added user and validate that the checkbox of managed externally is disabled
      get :edit, params: { id: added_au_id }
      assert_response :success
      assert_select 'form input#external' do |checkbox|
        assert_equal checkbox[0]['disabled'], 'disabled'
      end

      # create a user that is not managed externally
      parameters = {
        allowed_user: { kb_username: SecureRandom.uuid.to_s, description: SecureRandom.uuid.to_s },
        external: '0',
        password: 'jdbc',
        roles: nil
      }
      post :create, params: parameters
      assert_equal 'User was successfully configured', flash[:notice]
      assert_response 302
      added_au_id = response_path.gsub('/kaui/admin_allowed_users/', '')

      # edit the added user and validate that the password is not disabled
      get :edit, params: { id: added_au_id }
      assert_response :success
      assert_select 'form input#password' do |input|
        assert_nil input[0]['disabled']
      end
    end

    private

    def expected_response_path(id = nil)
      "/kaui/admin_allowed_users#{id.nil? ? '' : "/#{id}"}"
    end

    def extract_allowed_username
      extract_value_from_input_field('allowed_user_kb_username')
    end

    def extract_allowed_description
      extract_value_from_input_field('allowed_user_description')
    end

    def extract_allowed_id(response_body)
      fields = %r{<form.*action="/.*/.*/(?<id>.*?)".accept-charset=.*method="post">}.match(response_body)
      fields = %r{<a.href="http:/.*/.*/(?<id>.*?)">}.match(response_body) if fields.nil?

      fields.nil? ? nil : fields[:id]
    end
  end
end
