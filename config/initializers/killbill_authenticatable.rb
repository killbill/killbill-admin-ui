require 'devise/strategies/authenticatable'

module Devise
  module Strategies
    class KillbillAuthenticatable < Authenticatable
      # Invoked by warden to execute the strategy
      def authenticate!
        creds = params[:user] || {}
        kb_username = creds[:kb_username]
        kb_password = password
        api_key = creds[:api_key] || KillBillClient.api_key
        api_secret = creds[:api_password] || KillBillClient.api_secret

        # Find the associated user object
        resource = valid_password? && mapping.to.find_for_killbill_authentication(kb_username, kb_password, api_key, api_secret)
        return fail(:not_found_in_database) unless resource

        # Validate the credentials
        if validate(resource){ resource.valid_killbill_password?(kb_username, kb_password) }
          # Create the user if needed
          resource.after_killbill_authentication
          # Tell warden to halt the strategy and set the user in the appropriate scope
          success!(resource)
        end
      rescue Errno::ECONNREFUSED => e
        return fail(:killbill_not_available)
      end
    end
  end
end

Warden::Strategies.add(:killbill_authenticatable, Devise::Strategies::KillbillAuthenticatable)

Warden::Manager.after_set_user do |user, auth, opts|
  unless user.authenticated_with_killbill?
    scope = opts[:scope]
    auth.logout(scope)
    throw(:warden, :scope => scope, :reason => "Kill Bill session expired")
  end
end

Devise.add_module(:killbill_authenticatable,
                  :strategy => true,
                  :route => :session,
                  :controller => :sessions,
                  :model => 'kaui/killbill_authenticatable')
