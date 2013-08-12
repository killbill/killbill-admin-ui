require 'devise/strategies/authenticatable'

module Devise
  module Strategies
    class KillbillAuthenticatable < Authenticatable
      # Invoked by warden to execute the strategy
      def authenticate!
        resource = valid_password? && mapping.to.find_for_killbill_authentication(authentication_hash)
        return fail(:not_found_in_database) unless resource

        if validate(resource)
          resource.after_killbill_authentication
          success!(resource)
        end
      end
    end
  end
end

Warden::Strategies.add(:killbill_authenticatable, Devise::Strategies::KillbillAuthenticatable)

Devise.add_module(:killbill_authenticatable,
                  :strategy => true,
                  :route => :session,
                  :controller => :sessions,
                  :model => 'kaui/killbill_authenticatable')
