# frozen_string_literal: true

require 'test_helper'
require 'symmetric-encryption'

module Kaui
  # Kill Bill is stubbed (Kaui::User.find_permissions and KillBillClient::Model::Security.find_subject)
  class SsoCognitoControllerTest < Kaui::FunctionalTestHelperNoSetup
    ISSUER = 'https://cognito-idp.us-west-2.amazonaws.com/us-west-2_TestPool'
    CLIENT_ID = 'client-one'
    KB_SESSION_ID = 'kb-session-id'

    Subject = Struct.new(:principal, :is_authenticated)
    KbResponse = Struct.new(:session_id)

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
      @principal = nil
    end
    # rubocop:enable ThreadSafety/MutableClassInstanceVariable

    teardown do
      %w[KAUI_COGNITO_ISSUER KAUI_COGNITO_CLIENT_IDS KAUI_COGNITO_CLIENT_ID].each { |k| ENV.delete(k) }
      @saved_env.each { |k, v| ENV[k] = v }
      Kaui::CognitoJwtVerifier.clear_cache!
    end

    test 'routes the exchange and keeps the aviate alias' do
      assert_recognizes({ controller: 'kaui/sso_cognito', action: 'exchange' }, { method: 'post', path: '/sso/cognito/exchange' })
      assert_recognizes({ controller: 'kaui/sso_cognito', action: 'exchange' }, { method: 'post', path: '/sso/aviate/exchange' })
    end

    test 'answers 404 when not configured' do
      ENV.delete('KAUI_COGNITO_ISSUER')

      exchange(token, kb_username: 'bob', kb_password: 'secret')

      assert_response :not_found
      assert_match(/not enabled/, json['error'])
      assert_not_kb_login
    end

    test 'rejects a missing, invalid or expired token' do
      post :exchange
      assert_response :unauthorized

      exchange('garbage', kb_username: 'bob', kb_password: 'secret')
      assert_response :unauthorized
      assert_equal 'Invalid or expired token', json['error']

      exchange(token(exp: 1.minute.ago.to_i), kb_username: 'bob', kb_password: 'secret')
      assert_response :unauthorized

      exchange(token(aud: 'other-client'), kb_username: 'bob', kb_password: 'secret')
      assert_response :unauthorized
      assert_not_kb_login
    end

    #
    # Basic mode
    #

    test 'basic mode logs into Kill Bill with the password and selects the allowed tenant' do
      tenant = create_tenant
      allowed_user = Kaui::AllowedUser.create!(kb_username: 'bob')
      allowed_user.kaui_tenants << tenant

      exchange(token, kb_username: 'bob', kb_password: 'secret', target: '/accounts')

      assert_response :ok
      assert_equal 'http://test.host/accounts', json['redirectUrl']
      assert_equal [{ username: 'bob', password: 'secret' }], @kb_calls

      user = Kaui::User.find_by!(kb_username: 'bob')
      assert_equal KB_SESSION_ID, user.kb_session_id
      assert_signed_in_as user
      assert session[:aviate_sso]
      assert_equal tenant.kb_tenant_id, session[:kb_tenant_id]
      assert_equal tenant.id, session[:tenant_id]
    end

    test 'basic mode defaults the user to the email of the token' do
      exchange(token(email: 'Alice@Acme.com'), kb_password: 'secret')

      assert_response :ok
      assert_equal [{ username: 'alice@acme.com', password: 'secret' }], @kb_calls
      assert Kaui::User.exists?(kb_username: 'alice@acme.com')
    end

    test 'basic mode answers 401 when Kill Bill rejects the credentials' do
      @kb_error = KillBillClient::API::Unauthorized

      exchange(token, kb_username: 'bob', kb_password: 'wrong')

      assert_response :unauthorized
      assert_equal 'Invalid Kill Bill credentials', json['error']
      assert_not Kaui::User.exists?(kb_username: 'bob')
      assert_nil session[:aviate_sso]
    end

    test 'redirect url includes the context path and only targets known pages' do
      @request.env['SCRIPT_NAME'] = '/kaui'

      exchange(token, kb_username: 'bob', kb_password: 'secret', target: '/invoices/123')
      assert_equal 'http://test.host/kaui/invoices/123', json['redirectUrl']

      exchange(token, kb_username: 'bob', kb_password: 'secret')
      assert_equal 'http://test.host/kaui/', json['redirectUrl']

      ['https://evil.example.com', '//evil.example.com', '/admin', '/accounts/../admin', '/accountsfoo'].each do |target|
        exchange(token, kb_username: 'bob', kb_password: 'secret', target:)
        assert_equal 'http://test.host/kaui/', json['redirectUrl'], "target: #{target}"
      end
    end

    #
    # Bearer mode
    #

    test 'bearer mode logs into Kill Bill with the token and keys the user by the Kill Bill principal' do
      @principal = 'cognito:alice@acme.com'
      tenant = create_tenant
      jwt = token(email: 'alice@acme.com')

      exchange(jwt, tenant_api_key: tenant.api_key, tenant_api_secret: 'the-secret', target: '/accounts')

      assert_response :ok
      assert_equal 'http://test.host/accounts', json['redirectUrl']
      assert_equal [{ bearer: jwt }], @kb_calls

      user = Kaui::User.find_by!(kb_username: 'cognito:alice@acme.com')
      assert_equal KB_SESSION_ID, user.kb_session_id
      assert_not Kaui::User.exists?(kb_username: 'alice@acme.com')
      assert_signed_in_as user
      assert session[:aviate_sso]
      assert_predicate user, :cognito_principal?

      # The tenant is selected and the user is allowed on it
      assert_equal tenant.kb_tenant_id, session[:kb_tenant_id]
      assert_equal tenant.id, session[:tenant_id]
      assert_equal [tenant], Kaui::AllowedUser.find_by!(kb_username: 'cognito:alice@acme.com').kaui_tenants.to_a
    end

    test 'bearer mode is idempotent' do
      @principal = 'cognito:alice@acme.com'
      tenant = create_tenant

      2.times { exchange(token, tenant_api_key: tenant.api_key, tenant_api_secret: 'the-secret') }

      assert_response :ok
      assert_equal 1, Kaui::User.where(kb_username: 'cognito:alice@acme.com').count
      assert_equal 1, Kaui::AllowedUser.where(kb_username: 'cognito:alice@acme.com').count
      assert_equal 1, Kaui::AllowedUserTenant.count
    end

    test 'a bearer user and a basic user with the same email get separate rows' do
      @principal = 'cognito:alice@acme.com'
      tenant = create_tenant
      basic_user = Kaui::User.create!(kb_username: 'alice@acme.com', kb_session_id: 'basic-session')
      basic_allowed_user = Kaui::AllowedUser.create!(kb_username: 'alice@acme.com')

      exchange(token(email: 'alice@acme.com'), tenant_api_key: tenant.api_key, tenant_api_secret: 'the-secret')

      assert_response :ok
      assert_equal 2, Kaui::User.count
      assert_equal 'basic-session', basic_user.reload.kb_session_id
      assert_empty basic_allowed_user.reload.kaui_tenants
      assert_equal 1, Kaui::AllowedUser.find_by!(kb_username: 'cognito:alice@acme.com').kaui_tenants.count
    end

    test 'bearer mode answers 403 for an unknown tenant or a wrong secret, without any session' do
      @principal = 'cognito:alice@acme.com'
      tenant = create_tenant

      exchange(token, tenant_api_key: tenant.api_key, tenant_api_secret: 'wrong')
      assert_response :forbidden
      assert_match(/Unknown tenant or invalid tenant api secret/, json['error'])

      exchange(token, tenant_api_key: 'unknown', tenant_api_secret: 'the-secret')
      assert_response :forbidden

      assert_not_kb_login
      assert_equal 0, Kaui::User.count
      assert_equal 0, Kaui::AllowedUser.count
      assert_nil session[:aviate_sso]
      assert_nil session[:kb_tenant_id]
    end

    test 'bearer mode requires the api key and the api secret together' do
      exchange(token, tenant_api_key: 'only-the-key')
      assert_response :bad_request
      assert_not_kb_login
    end

    test 'bearer mode without tenant credentials leaves the tenant selection to Kaui' do
      @principal = 'cognito:alice@acme.com'

      exchange(token)

      assert_response :ok
      assert_nil session[:kb_tenant_id]
      assert session[:aviate_sso]
    end

    test 'bearer mode answers 401 when Kill Bill has no Cognito realm' do
      @kb_error = KillBillClient::API::Unauthorized

      exchange(token, tenant_api_key: create_tenant.api_key, tenant_api_secret: 'the-secret')

      assert_response :unauthorized
      assert_match(/Cognito authentication is not enabled on this Kill Bill/, json['error'])
      assert_equal 0, Kaui::User.count
      assert_nil session[:aviate_sso]
    end

    test 'serves the session expired page' do
      get :session_expired

      assert_response :ok
      assert_match(/reopen Kaui/, response.body)
    end

    private

    def exchange(jwt, **params)
      @request.headers['Authorization'] = "Bearer #{jwt}"
      stub_kill_bill { Kaui::CognitoJwtVerifier.stub(:fetch_jwks, @jwks) { post :exchange, params: } }
    end

    def stub_kill_bill(&)
      find_permissions = lambda do |options|
        @kb_calls << options
        raise @kb_error.new(nil, nil) if @kb_error

        KbResponse.new(KB_SESSION_ID)
      end
      find_subject = ->(_options) { Subject.new(@principal, true) }

      Kaui::User.stub(:find_permissions, find_permissions) do
        KillBillClient::Model::Security.stub(:find_subject, find_subject, &)
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

    def create_tenant
      Kaui::Tenant.create!(name: 'tenant-one', api_key: 'tenant-key', api_secret: 'the-secret', kb_tenant_id: SecureRandom.uuid)
    end

    def json
      JSON.parse(response.body)
    end

    def assert_not_kb_login
      assert_empty @kb_calls
    end

    def assert_signed_in_as(user)
      assert_equal user, request.env['warden'].user(:user)
    end
  end
end
