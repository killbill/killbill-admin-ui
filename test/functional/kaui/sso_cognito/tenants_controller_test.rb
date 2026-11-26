# frozen_string_literal: true

require 'test_helper'
require 'symmetric-encryption'

module Kaui
  module SsoCognito
    # Kill Bill is stubbed (Kaui::User.find_permissions, KillBillClient::Model::Security.find_subject and Kaui::AdminTenant.find_by_api_key)
    class TenantsControllerTest < Kaui::FunctionalTestHelperNoSetup
      ISSUER = 'https://cognito-idp.us-west-2.amazonaws.com/us-west-2_TestPool'
      CLIENT_ID = 'client-one'
      KB_SESSION_ID = 'kb-session-id'
      KB_TENANT_ID = '11111111-1111-1111-1111-111111111111'

      Subject = Struct.new(:principal, :is_authenticated)
      KbResponse = Struct.new(:session_id)
      KbTenant = Struct.new(:tenant_id)

      # rubocop:disable ThreadSafety/MutableClassInstanceVariable
      setup do
        Kaui::ApplicationRecord.subclasses.each(&:delete_all)
        SymmetricEncryption.load!('config/symmetric-encryption.yml', 'test')

        @saved_env = ENV.to_h.slice('KAUI_COGNITO_ISSUER', 'KAUI_COGNITO_CLIENT_IDS', 'KAUI_COGNITO_CLIENT_ID')
        @saved_env.each_key { |k| ENV.delete(k) }
        ENV['KAUI_COGNITO_ISSUER'] = ISSUER
        ENV['KAUI_COGNITO_CLIENT_IDS'] = CLIENT_ID
        Kaui::CognitoJwtVerifier.clear_cache!

        @routes = Kaui::Engine.routes
        @rsa_key = OpenSSL::PKey::RSA.generate(2048)
        @jwks = [JWT::JWK.new(@rsa_key, kid: 'kid-1').export.stringify_keys]
        @kb_calls = []
        @kb_tenant_calls = []
        @kb_tenant = KbTenant.new(KB_TENANT_ID)
        @kb_tenant_error = nil
        @principal = nil
      end
      # rubocop:enable ThreadSafety/MutableClassInstanceVariable

      teardown do
        %w[KAUI_COGNITO_ISSUER KAUI_COGNITO_CLIENT_IDS KAUI_COGNITO_CLIENT_ID].each { |k| ENV.delete(k) }
        @saved_env.each { |k, v| ENV[k] = v }
        Kaui::CognitoJwtVerifier.clear_cache!
      end

      test 'routes the registration and keeps the aviate alias' do
        assert_recognizes({ controller: 'kaui/sso_cognito/tenants', action: 'create' }, { method: 'post', path: '/sso/cognito/tenants' })
        assert_recognizes({ controller: 'kaui/sso_cognito/tenants', action: 'create' }, { method: 'post', path: '/sso/aviate/tenants' })
      end

      test 'answers 404 when not configured' do
        ENV.delete('KAUI_COGNITO_ISSUER')

        register(token, **basic_params)

        assert_response :not_found
        assert_match(/not enabled/, json['error'])
        assert_empty @kb_calls
      end

      test 'rejects a missing, invalid or expired token' do
        post :create
        assert_response :unauthorized

        register('garbage', **basic_params)
        assert_response :unauthorized

        register(token(exp: 1.minute.ago.to_i), **basic_params)
        assert_response :unauthorized
        assert_empty @kb_calls
        assert_equal 0, Kaui::Tenant.count
      end

      test 'registers the tenant and grants the user access (basic mode)' do
        register(token, **basic_params)

        assert_response :created
        tenant = Kaui::Tenant.find_by!(name: 'my-tenant')
        assert_equal({ 'id' => tenant.id, 'name' => 'my-tenant', 'kbTenantId' => KB_TENANT_ID, 'tenantKey' => 'tenant-key' }, json)
        assert_equal 'tenant-key', tenant.api_key
        assert_equal 'tenant-secret', tenant.api_secret
        assert_equal KB_TENANT_ID, tenant.kb_tenant_id
        assert_equal ['bob'], tenant.kaui_allowed_users.map(&:kb_username)

        # Kill Bill was asked about the tenant with its own credentials
        assert_equal [{ username: 'bob', session_id: KB_SESSION_ID, api_key: 'tenant-key', api_secret: 'tenant-secret' }], @kb_tenant_calls
      end

      test 'registers the tenant for the principal of the token (bearer mode)' do
        @principal = 'cognito:alice@acme.com'

        # No tenant is known to Kaui yet: it must not be required, unlike the exchange
        register(token, **tenant_params)

        assert_response :created
        assert_equal ['cognito:alice@acme.com'], Kaui::Tenant.find_by!(name: 'my-tenant').kaui_allowed_users.map(&:kb_username)
        assert_equal [{ bearer: token_used }], @kb_calls
      end

      test 'does not touch the session of the browser' do
        register(token, **basic_params)

        assert_response :created
        assert_nil request.env['warden'].user(:user)
        assert_nil session[:aviate_sso]
        assert_nil session[:kb_tenant_id]
      end

      test 'requires the parameters' do
        %i[name tenantKey tenantSecret kbTenantId].each do |missing|
          register(token, **basic_params.except(missing))

          assert_response :bad_request, missing.to_s
          assert_match(/#{missing}/, json['error'])
        end
        assert_equal 0, Kaui::Tenant.count
        assert_equal 0, Kaui::AllowedUser.count
      end

      test 'answers 401 for invalid Kill Bill credentials' do
        @kb_error = KillBillClient::API::Unauthorized

        register(token, **basic_params)

        assert_response :unauthorized
        assert_equal 'Invalid Kill Bill credentials', json['error']
        assert_equal 0, Kaui::Tenant.count
      end

      test 'answers 403 when Kill Bill rejects the tenant credentials' do
        [KillBillClient::API::Unauthorized, KillBillClient::API::Forbidden, KillBillClient::API::NotFound, KillBillClient::API::Conflict].each do |error|
          @kb_tenant_error = error.new(nil, nil)

          register(token, **basic_params)

          assert_response :forbidden, error.name
          assert_match(/rejected the tenant credentials/, json['error'])
        end
        assert_equal 0, Kaui::Tenant.count
        assert_equal 0, Kaui::AllowedUser.count
      end

      test 'answers 403 for an unknown api key reported by Kill Bill as a server error' do
        @kb_tenant_error = KillBillClient::API::InternalServerError.new(nil, nil)
        @kb_tenant_error.define_singleton_method(:message) { 'TenantCacheLoader cannot find value for key tenant-key' }

        register(token, **basic_params)

        assert_response :forbidden
        assert_equal 0, Kaui::Tenant.count
      end

      test 'answers 500 for any other Kill Bill error' do
        @kb_tenant_error = KillBillClient::API::InternalServerError.new(nil, nil)

        register(token, **basic_params)

        assert_response :internal_server_error
        assert_equal 'Tenant registration failed', json['error']
        assert_equal 0, Kaui::Tenant.count
      end

      test 'answers 403 when the key is not the tenant kbTenantId' do
        register(token, **basic_params, kbTenantId: SecureRandom.uuid)

        assert_response :forbidden
        assert_match(/not the Kill Bill tenant/, json['error'])
        assert_equal 0, Kaui::Tenant.count
      end

      test 'is idempotent and grants the access to another user' do
        register(token, **basic_params)
        assert_response :created

        register(token, **basic_params, kb_username: 'carol')
        assert_response :ok
        assert_equal 1, Kaui::Tenant.count
        assert_equal %w[bob carol], Kaui::Tenant.first.kaui_allowed_users.map(&:kb_username).sort

        register(token, **basic_params)
        assert_response :ok
        assert_equal 2, Kaui::Tenant.first.kaui_allowed_users.count
      end

      test 'answers 409 when the name is used by another tenant' do
        Kaui::Tenant.create!(name: 'my-tenant', api_key: 'other-key', api_secret: 'other-secret', kb_tenant_id: SecureRandom.uuid)

        register(token, **basic_params)

        assert_response :conflict
        assert_equal 1, Kaui::Tenant.count
        assert_equal 0, Kaui::AllowedUser.count
      end

      test 'keeps the CSRF protection for the requests without a bearer token' do
        Kaui::SsoCognito::TenantsController.allow_forgery_protection = true

        post :create, params: basic_params
        assert_response :unauthorized
        assert_empty @kb_calls

        register(token, **basic_params)
        assert_response :created
      ensure
        Kaui::SsoCognito::TenantsController.allow_forgery_protection = false
      end

      private

      def tenant_params
        { name: 'my-tenant', tenantKey: 'tenant-key', tenantSecret: 'tenant-secret', kbTenantId: KB_TENANT_ID }
      end

      def basic_params
        { kb_username: 'bob', kb_password: 'secret' }.merge(tenant_params)
      end

      def register(jwt, **params)
        @token_used = jwt
        @request.headers['Authorization'] = "Bearer #{jwt}"
        stub_kill_bill { Kaui::CognitoJwtVerifier.stub(:fetch_jwks, @jwks) { post :create, params: } }
      end

      attr_reader :token_used

      def stub_kill_bill(&)
        find_permissions = lambda do |options|
          @kb_calls << options
          raise @kb_error.new(nil, nil) if @kb_error

          KbResponse.new(KB_SESSION_ID)
        end
        find_subject = ->(_options) { Subject.new(@principal, true) }
        find_by_api_key = lambda do |_api_key, options|
          @kb_tenant_calls << options
          raise @kb_tenant_error if @kb_tenant_error

          @kb_tenant
        end

        Kaui::User.stub(:find_permissions, find_permissions) do
          KillBillClient::Model::Security.stub(:find_subject, find_subject) do
            Kaui::AdminTenant.stub(:find_by_api_key, find_by_api_key, &)
          end
        end
      end

      def token(**claims)
        payload = {
          'iss' => ISSUER,
          'aud' => CLIENT_ID,
          'token_use' => 'id',
          'email' => 'alice@acme.com',
          'exp' => 10.minutes.from_now.to_i
        }.merge(claims.stringify_keys)
        JWT.encode(payload, @rsa_key, 'RS256', { kid: 'kid-1' })
      end

      def json
        JSON.parse(response.body)
      end
    end
  end
end
