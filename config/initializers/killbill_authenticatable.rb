# frozen_string_literal: true

require 'devise/strategies/authenticatable'
require 'jwt'

module Devise
  module Strategies
    module KillbillHelpers
      def kb_authenticate!(kb_username, creds)
        # Find the associated user object (see find_for_killbill_authentication in app/models/kaui/killbill_authenticatable.rb)
        resource = mapping.to.find_for_killbill_authentication(kb_username)

        # Validate the credentials (see valid_killbill_password? in app/models/kaui/killbill_authenticatable.rb)
        return unless validate(resource) { resource.valid_killbill_password?(creds) }

        # Create the user if needed
        resource.after_killbill_authentication
        # Tell warden to halt the strategy and set the user in the appropriate scope
        success!(resource)
      end
    end

    class KillbillAuthenticatable < Authenticatable
      include KillbillHelpers

      # Invoked by Warden::Strategies::Base#_run! to execute the strategy
      def authenticate!
        return false unless valid_password?

        user = params[:user] || {}
        kb_authenticate!(user[:kb_username], { username: user[:kb_username], password: })
      end
    end

    # Warden strategy to authenticate an user through a JWT token in the `Authorization` request header
    class KillbillJWTAuthenticatable < Authenticatable
      # Must match the Kill Bill configuration (e.g. org.killbill.security.auth0.usernameClaim)
      mattr_accessor :username_claim
      self.username_claim = 'sub'

      include KillbillHelpers

      # Invoked by Warden::Strategies::Base#_run! to execute the strategy
      def authenticate!
        payload, = ::JWT.decode(token, nil, false)
        kb_username = payload[username_claim].presence
        return false unless kb_username

        kb_authenticate!(kb_username, { bearer: token })
      end

      def valid?
        !token.nil?
      end

      private

      def token
        @token ||= begin
          auth = env['HTTP_AUTHORIZATION']
          if auth
            method, token = auth.split
            method == 'Bearer' ? token : nil
          else
            nil
          end
        end
      end
    end
  end
end

Warden::Strategies.add(:killbill_authenticatable, Devise::Strategies::KillbillAuthenticatable)
Warden::Strategies.add(:killbill_jwt, Devise::Strategies::KillbillJWTAuthenticatable)

Warden::Manager.after_set_user do |user, auth, opts|
  unless user.authenticated_with_killbill?
    scope = opts[:scope]
    auth.logout(scope)
    throw(:warden, scope:, reason: 'Kill Bill session expired')
  end
end

Devise.add_module(:killbill_authenticatable,
                  strategy: true,
                  route: :session,
                  controller: :sessions,
                  model: 'kaui/killbill_authenticatable')

Devise::Strategies::KillbillJWTAuthenticatable.username_claim = if defined?(JRUBY_VERSION)
                                                                  java.lang.System.getProperty('kaui.jwt.username_claim', ENV['KAUI_USERNAME_CLAIM'] || 'sub')
                                                                else
                                                                  ENV['KAUI_USERNAME_CLAIM'] || 'sub'
                                                                end
