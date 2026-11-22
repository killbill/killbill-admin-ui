# frozen_string_literal: true

require 'jwt'
require 'net/http'
require 'json'

module Kaui
  # Verifies AWS Cognito tokens (ID or access tokens) for the optional Cognito token exchange (see Kaui::SsoCognitoController).
  #
  # The feature is disabled unless an issuer and at least one app client id are configured. Each setting can be set
  # either as a system property (JRuby/Tomcat) or as an environment variable (containers):
  #
  #   issuer:     -Dkaui.cognito.issuer=https://cognito-idp.<region>.amazonaws.com/<user-pool-id>
  #               KAUI_COGNITO_ISSUER
  #   client ids: -Dkaui.cognito.client_ids=<id1>,<id2> (or the legacy single -Dkaui.cognito.client_id=<id>)
  #               KAUI_COGNITO_CLIENT_IDS=<id1>,<id2> (or KAUI_COGNITO_CLIENT_ID=<id>)
  class CognitoJwtVerifier
    # Minimum delay (in seconds) between two refreshes of the JWKS triggered by an unknown 'kid'
    JWKS_MIN_REFRESH_INTERVAL = 60
    JWKS_TIMEOUT = 5

    JwksEntry = Struct.new(:keys, :fetched_at)

    JWKS_CACHE = Concurrent::Map.new
    JWKS_LOCK = Mutex.new

    class << self
      def configured?
        issuer.present? && client_ids.any?
      end

      # Cognito issuer URL (user pool), e.g. https://cognito-idp.{region}.amazonaws.com/{user-pool-id}
      def issuer
        config_value('kaui.cognito.issuer', 'KAUI_COGNITO_ISSUER').to_s.strip.chomp('/').presence
      end

      # Accepted Cognito app client ids (the 'aud' of ID tokens)
      def client_ids
        from_properties = split_ids(system_property('kaui.cognito.client_ids')) + split_ids(system_property('kaui.cognito.client_id'))
        return from_properties.uniq if from_properties.any?

        (split_ids(ENV.fetch('KAUI_COGNITO_CLIENT_IDS', nil)) + split_ids(ENV.fetch('KAUI_COGNITO_CLIENT_ID', nil))).uniq
      end

      # Returns the verified claims or raises JWT::DecodeError (including JWT::ExpiredSignature)
      def verify!(jwt_token)
        raise JWT::DecodeError, 'Cognito token verification is not configured' unless configured?

        # Extract the header WITHOUT verification - only to get the 'kid' for key lookup.
        # This is safe because the full verification happens below with the public key.
        header = begin
          JWT.decode(jwt_token, nil, false)[1]
        rescue JWT::DecodeError => e
          raise JWT::DecodeError, "Invalid JWT format: #{e.message}"
        end

        kid = header['kid']
        raise JWT::DecodeError, 'Missing kid in token header' if kid.nil?

        jwk = find_jwk(kid)
        raise JWT::DecodeError, "Unknown key ID: #{kid}" if jwk.nil?

        decoded_token = JWT.decode(
          jwt_token,
          JWT::JWK.import(jwk).public_key,
          true,
          {
            algorithm: 'RS256',
            iss: issuer,
            verify_iss: true,
            aud: client_ids,
            verify_aud: true
          }
        )

        claims = decoded_token[0]
        validate_cognito_claims!(claims)
        claims
      end

      # Drops the cached JWKS (mostly for tests)
      def clear_cache!
        JWKS_CACHE.clear
      end

      # Fetches the JWKS (JSON Web Key Set) of the issuer from Cognito
      def fetch_jwks
        uri = URI("#{issuer}/.well-known/jwks.json")
        response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https', open_timeout: JWKS_TIMEOUT, read_timeout: JWKS_TIMEOUT) do |http|
          http.request(Net::HTTP::Get.new(uri))
        end
        raise "Failed to fetch JWKS from Cognito: #{response.code} #{response.message}" unless response.is_a?(Net::HTTPSuccess)

        JSON.parse(response.body).fetch('keys')
      rescue StandardError => e
        Rails.logger.error("Failed to fetch JWKS: #{e.message}")
        raise
      end

      private

      # Finds a JWK by its key ID. The JWKS is cached, and refetched (at most once per JWKS_MIN_REFRESH_INTERVAL)
      # when the key ID is unknown, to pick up Cognito key rotations without restarting Kaui.
      def find_jwk(kid)
        entry = JWKS_CACHE[issuer] || refresh_jwks(nil)
        jwk = entry.keys.find { |key| key['kid'] == kid }
        return jwk if jwk

        refresh_jwks(entry)
        JWKS_CACHE[issuer]&.keys&.find { |key| key['kid'] == kid }
      end

      # Refetches the JWKS, unless another thread already did it, or it was fetched too recently
      def refresh_jwks(stale_entry)
        JWKS_LOCK.synchronize do
          current = JWKS_CACHE[issuer]
          return current if current && (!current.equal?(stale_entry) || (now - current.fetched_at) < JWKS_MIN_REFRESH_INTERVAL)

          keys = begin
            fetch_jwks
          rescue StandardError
            # Keep serving (and don't hammer Cognito for) the keys we already have; fail only if we have none
            raise if current.nil?

            current.keys
          end
          JWKS_CACHE[issuer] = JwksEntry.new(keys, now)
        end
      end

      def now
        Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end

      # Validates Cognito-specific claims in the token
      def validate_cognito_claims!(claims)
        # Verify token_use is either 'id' (ID token) or 'access' (access token)
        token_use = claims['token_use']
        raise JWT::DecodeError, "Invalid token_use: #{token_use}" unless %w[id access].include?(token_use)
      end

      def split_ids(value)
        value.to_s.split(',').map(&:strip).compact_blank
      end

      # System property (JRuby only) first, then environment variable, as in the Kaui standalone initializers
      def config_value(property, env_var)
        system_property(property).presence || ENV.fetch(env_var, nil)
      end

      def system_property(property)
        defined?(JRUBY_VERSION) ? java.lang.System.getProperty(property) : nil
      end
    end
  end
end
