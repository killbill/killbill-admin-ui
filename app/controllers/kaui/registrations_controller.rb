module Kaui
  class RegistrationsController < Devise::RegistrationsController
    layout Kaui.config[:layout]

    skip_before_action :check_for_redirect_to_tenant_screen

    def create
      @user = Kaui::AllowedUser.new(:kb_username => sign_up_params.require(:kb_username))

      if Kaui::AllowedUser.find_by_kb_username(@user.kb_username).present?
        flash.now[:error] = "User with name #{@user.kb_username} already exists!"
        render :new and return
      end

      # Create locally and in KB
      @user.create_in_kb!(sign_up_params.require(:password),
                          Kaui.default_roles,
                          'Kaui::RegistrationsController',
                          params[:reason],
                          params[:comment],
                          root_options_for_klient)

      flash[:notice] = "User #{@user.kb_username} successfully created, please login"
      redirect_to new_user_session_path
    end

    private

    def root_options_for_klient
      {
          :username => Kaui.root_username,
          :password => Kaui.root_password,
          :api_key => Kaui.root_api_key,
          :api_secret => Kaui.root_api_secret
      }
    end
  end
end
