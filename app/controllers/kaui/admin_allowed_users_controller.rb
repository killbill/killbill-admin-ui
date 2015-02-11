module Kaui
  class AdminAllowedUsersController < Kaui::EngineController

    skip_before_filter :check_for_redirect_to_tenant_screen

    def index
      @allowed_users = Kaui::AllowedUser.all
    end

    def new
      @allowed_user = Kaui::AllowedUser.new
    end

    def create

      param_allowed_user = params[:allowed_user]
      existing_user = Kaui::AllowedUser.find_by_kb_username(param_allowed_user[:kb_username])
      if existing_user
        flash[:error] = "Allowed User with name #{param_allowed_user[:kb_username]} already exists!"
        redirect_to admin_allowed_users_path and return
      end

      new_user = Kaui::AllowedUser.new
      new_user.kb_username = param_allowed_user[:kb_username]
      new_user.description = param_allowed_user[:description]
      new_user.save!

      redirect_to admin_allowed_user_path(new_user[:id]), :notice => 'Allowed User was successfully configured'
    end

    def show
      @allowed_user = Kaui::AllowedUser.find(params[:id])
      render
    end
  end
end
