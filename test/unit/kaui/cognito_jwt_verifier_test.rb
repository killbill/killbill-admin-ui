# frozen_string_literal: true

require 'test_helper'

module Kaui
  class CognitoJwtVerifierTest < ActiveSupport::TestCase
    ISSUER = 'https://cognito-idp.us-west-2.amazonaws.com/us-west-2_TestPool'
    CLIENT_ID = 'client-one'

    setup do
      @saved_env = ENV.to_h.slice('KAUI_COGNITO_ISSUER', 'KAUI_COGNITO_CLIENT_IDS', 'KAUI_COGNITO_CLIENT_ID')
      @saved_env.each_key { |k| ENV.delete(k) }
      ENV['KAUI_COGNITO_ISSUER'] = ISSUER
      ENV['KAUI_COGNITO_CLIENT_IDS'] = CLIENT_ID
      Kaui::CognitoJwtVerifier.clear_cache!
      @key = OpenSSL::PKey::RSA.generate(2048)
    end

    teardown do
      %w[KAUI_COGNITO_ISSUER KAUI_COGNITO_CLIENT_IDS KAUI_COGNITO_CLIENT_ID].each { |k| ENV.delete(k) }
      @saved_env.each { |k, v| ENV[k] = v }
      Kaui::CognitoJwtVerifier.clear_cache!
    end

    test 'is disabled unless configured' do
      assert_predicate Kaui::CognitoJwtVerifier, :configured?

      ENV.delete('KAUI_COGNITO_ISSUER')
      assert_not Kaui::CognitoJwtVerifier.configured?

      ENV['KAUI_COGNITO_ISSUER'] = ISSUER
      ENV.delete('KAUI_COGNITO_CLIENT_IDS')
      assert_not Kaui::CognitoJwtVerifier.configured?
    end

    test 'reads multiple client ids from the environment' do
      ENV['KAUI_COGNITO_CLIENT_IDS'] = ' a , b,,c '
      ENV['KAUI_COGNITO_CLIENT_ID'] = 'd'
      assert_equal %w[a b c d], Kaui::CognitoJwtVerifier.client_ids
    end

    test 'strips the trailing slash of the issuer' do
      ENV['KAUI_COGNITO_ISSUER'] = "#{ISSUER}/"
      assert_equal ISSUER, Kaui::CognitoJwtVerifier.issuer
    end

    test 'verifies a valid token' do
      with_jwks([jwk('kid-1')]) do
        claims = Kaui::CognitoJwtVerifier.verify!(token('kid-1', email: 'alice@acme.com'))
        assert_equal 'alice@acme.com', claims['email']
      end
    end

    test 'accepts tokens of every configured client id and rejects the others' do
      ENV['KAUI_COGNITO_CLIENT_IDS'] = "#{CLIENT_ID},client-two"
      with_jwks([jwk('kid-1')]) do
        assert_equal 'client-two', Kaui::CognitoJwtVerifier.verify!(token('kid-1', aud: 'client-two'))['aud']
        assert_equal CLIENT_ID, Kaui::CognitoJwtVerifier.verify!(token('kid-1', aud: CLIENT_ID))['aud']
        assert_raises(JWT::InvalidAudError) { Kaui::CognitoJwtVerifier.verify!(token('kid-1', aud: 'client-three')) }
      end
    end

    test 'rejects a wrong issuer, an expired token, a bad signature and an unsupported token_use' do
      with_jwks([jwk('kid-1')]) do
        assert_raises(JWT::InvalidIssuerError) { Kaui::CognitoJwtVerifier.verify!(token('kid-1', iss: 'https://evil.example.com')) }
        assert_raises(JWT::ExpiredSignature) { Kaui::CognitoJwtVerifier.verify!(token('kid-1', exp: 1.minute.ago.to_i)) }
        assert_raises(JWT::DecodeError) { Kaui::CognitoJwtVerifier.verify!(token('kid-1', token_use: 'refresh')) }
        assert_raises(JWT::VerificationError) { Kaui::CognitoJwtVerifier.verify!(token('kid-1', signing_key: OpenSSL::PKey::RSA.generate(2048))) }
        assert_raises(JWT::DecodeError) { Kaui::CognitoJwtVerifier.verify!('not-a-jwt') }
      end
    end

    test 'refetches the JWKS when the kid is unknown, at most once per minute' do
      fetches = 0
      jwks = [jwk('old-kid')]
      now = 1000.0

      Kaui::CognitoJwtVerifier.stub(:fetch_jwks, lambda {
        fetches += 1
        jwks
      }) do
        Kaui::CognitoJwtVerifier.stub(:now, -> { now }) do
          assert Kaui::CognitoJwtVerifier.verify!(token('old-kid'))
          assert_equal 1, fetches

          # Cognito rotates its keys
          jwks = [jwk('new-kid')]

          # Too soon: no refetch, the unknown kid is rejected
          now += 10
          assert_raises(JWT::DecodeError) { Kaui::CognitoJwtVerifier.verify!(token('new-kid')) }
          assert_equal 1, fetches

          # Later: the JWKS is refetched
          now += Kaui::CognitoJwtVerifier::JWKS_MIN_REFRESH_INTERVAL
          assert Kaui::CognitoJwtVerifier.verify!(token('new-kid'))
          assert_equal 2, fetches

          # Known kids don't trigger any fetch
          assert Kaui::CognitoJwtVerifier.verify!(token('new-kid'))
          assert_equal 2, fetches
        end
      end
    end

    test 'keeps the cached keys when the refresh fails' do
      calls = 0
      fetch = lambda do
        calls += 1
        raise 'Cognito is down' if calls > 1

        [jwk('kid-1')]
      end

      Kaui::CognitoJwtVerifier.stub(:fetch_jwks, fetch) do
        Kaui::CognitoJwtVerifier.stub(:now, -> { 1000.0 }) do
          assert Kaui::CognitoJwtVerifier.verify!(token('kid-1'))
        end
        Kaui::CognitoJwtVerifier.stub(:now, -> { 2000.0 }) do
          assert_raises(JWT::DecodeError) { Kaui::CognitoJwtVerifier.verify!(token('unknown-kid')) }
          assert Kaui::CognitoJwtVerifier.verify!(token('kid-1'))
        end
      end
    end

    private

    def with_jwks(jwks, &)
      Kaui::CognitoJwtVerifier.stub(:fetch_jwks, jwks, &)
    end

    def jwk(kid, key = @key)
      JWT::JWK.new(key, kid:).export.stringify_keys
    end

    def token(kid, signing_key: @key, **claims)
      payload = {
        'iss' => ISSUER,
        'aud' => CLIENT_ID,
        'token_use' => 'id',
        'email' => 'alice@acme.com',
        'exp' => 10.minutes.from_now.to_i
      }.merge(claims.stringify_keys)
      JWT.encode(payload, signing_key, 'RS256', { kid: })
    end
  end
end
