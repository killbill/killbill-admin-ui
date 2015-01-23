module Kaui
  # Subclassed to specify the correct layout
  class SessionsController < Devise::SessionsController
    layout Kaui.config[:layout]

    skip_before_filter :check_for_redirect_to_tenant_screen

    protected

    # Override after_sign_in_path_for to not have to rely on the default 'root' config which we want to keep on home#index
    def after_sign_in_path_for(resource)
      # Clear the tenant_id from the cookie to not rely on old cookie data
      session[:kb_tenant_id] = nil
      Kaui.tenant_home_path.call
    end

  end
end
