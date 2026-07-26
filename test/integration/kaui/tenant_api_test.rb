# frozen_string_literal: true

require 'test_helper'

module Kaui
  class TenantApiTest < IntegrationTestHelper
    setup do
      sign_in_as_admin
    end

    test 'POST create_tenant creates a new tenant successfully' do
      tenant_params = {
        name: 'API Created Tenant',
        tenant_key: 'api_tenant_key_001',
        tenant_secret: 'api_tenant_secret_001',
        kb_tenant_id: 'api-kb-tenant-id-001'
      }

      assert_difference -> { Kaui::Tenant.count } => 1,
                        -> { Kaui::AllowedUserTenant.count } => 1 do
        post '/kaui/admin_tenants/create_tenant', params: tenant_params, as: :json
      end

      assert_response :created
      json = JSON.parse(response.body)
      assert_equal 'API Created Tenant', json['name']
      assert_equal 'api-kb-tenant-id-001', json['kb_tenant_id']
      assert_equal 'api_tenant_key_001', json['api_key']
      assert_not_nil json['id']
      assert_not_nil json['created_at']
    end

    test 'POST create_tenant returns 400 when required params are missing' do
      post '/kaui/admin_tenants/create_tenant', params: { name: 'Test' }, as: :json

      assert_response :bad_request
      json = JSON.parse(response.body)
      assert_includes json['error'], 'Missing required parameters'
    end

    test 'POST create_tenant returns 409 when tenant name already exists' do
      # Create a tenant first
      post '/kaui/admin_tenants/create_tenant',
           params: { name: 'Duplicate Test', tenant_key: 'dup_key_1', tenant_secret: 'dup_secret_1', kb_tenant_id: 'dup-kb-id-1' },
           as: :json
      assert_response :created

      # Try to create another with the same name
      post '/kaui/admin_tenants/create_tenant',
           params: { name: 'Duplicate Test', tenant_key: 'dup_key_2', tenant_secret: 'dup_secret_2', kb_tenant_id: 'dup-kb-id-2' },
           as: :json

      assert_response :conflict
      json = JSON.parse(response.body)
      assert_includes json['error'], 'already exists'
    end

    test 'POST create_tenant returns 409 when kb_tenant_id already exists' do
      # Create a tenant first
      post '/kaui/admin_tenants/create_tenant',
           params: { name: 'First Tenant', tenant_key: 'key_a', tenant_secret: 'secret_a', kb_tenant_id: 'shared-kb-id' },
           as: :json
      assert_response :created

      # Try to create another with the same kb_tenant_id
      post '/kaui/admin_tenants/create_tenant',
           params: { name: 'Second Tenant', tenant_key: 'key_b', tenant_secret: 'secret_b', kb_tenant_id: 'shared-kb-id' },
           as: :json

      assert_response :conflict
      json = JSON.parse(response.body)
      assert_includes json['error'], 'already exists'
    end

    test 'POST create_tenant requires authentication' do
      # Sign out first
      sign_out :user

      post '/kaui/admin_tenants/create_tenant',
           params: { name: 'No Auth', tenant_key: 'no_auth', tenant_secret: 'no_auth', kb_tenant_id: 'no-auth-id' },
           as: :json

      assert_response :redirect
      assert_redirected_to SIGN_IN_PATH
    end

    private

    def sign_in_as_admin
      post SIGN_IN_PATH, params: { user: { kb_username: USERNAME, password: PASSWORD } }
      assert_redirected_to TENANTS_PATH
      follow_redirect!

      # Select the first tenant
      tenant = Kaui::Tenant.first
      post select_tenant_path, params: { tenant_id: tenant.id } if tenant
    rescue StandardError
      # May already be signed in from setup
    end
  end
end
