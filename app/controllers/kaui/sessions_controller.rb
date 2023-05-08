# frozen_string_literal: true

module Kaui
  # Subclassed to specify the correct layout
  class SessionsController < Devise::SessionsController
    layout Kaui.config[:layout]

    skip_before_action :check_for_redirect_to_tenant_screen, raise: false

    # The sign-in flow eventually calls authenticate! from config/initializers/killbill_authenticatable.rb

    protected

    # Override after_sign_in_path_for to not have to rely on the default 'root' config which we want to keep on home#index
    def after_sign_in_path_for(_resource)
      # Clear the tenant_id from the cookie to not rely on old cookie data
      session[:kb_tenant_id] = nil
      stored_location_for(:user) || Kaui.tenant_home_path.call
    end

    def after_sign_out_path_for(_resource)
      kaui_path
    end

    def require_no_authentication
      super
      # Remove the somewhat confusing message "You are already signed in."
      flash.discard(:alert) if flash[:alert] == I18n.t('devise.failure.already_authenticated')
    end
  end
end
