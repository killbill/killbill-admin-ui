# frozen_string_literal: true

module Kaui
  class AdminAllowedUsersController < Kaui::EngineController
    skip_before_action :check_for_redirect_to_tenant_screen

    def index
      @allowed_users = retrieve_allowed_users_for_current_user
    end

    def new
      @allowed_user = Kaui::AllowedUser.new
      @is_killbill_managed = true

      @roles = []
    end

    def create
      @is_killbill_managed = nil
      @allowed_user = Kaui::AllowedUser.new(allowed_user_params)

      existing_user = Kaui::AllowedUser.find_by_kb_username(@allowed_user.kb_username)
      if existing_user.blank?
        if params[:external] == '1'
          # Create locally only
          @allowed_user.save!
        else
          @allowed_user.create_in_kb!(params.require(:password),
                                      params[:roles].blank? ? [] : params[:roles].split(','),
                                      current_user.kb_username,
                                      params[:reason],
                                      params[:comment],
                                      options_for_klient)
        end

        redirect_to kaui_engine.admin_allowed_user_path(@allowed_user.id), notice: 'User was successfully configured'
      else
        flash[:error] = "User with name #{@allowed_user.kb_username} already exists!"
        @roles = roles_for_user(existing_user)
        render :new and return
      end
    end

    def show
      @allowed_user = Kaui::AllowedUser.find(params.require(:id))
      raise ActiveRecord::RecordNotFound, "Could not find user #{@allowed_user.id}" unless current_user.root? || @allowed_user.kb_username == current_user.kb_username

      @roles = roles_for_user(@allowed_user)

      tenants_for_current_user = retrieve_tenants_for_current_user
      @tenants = Kaui::Tenant.all.select { |tenant| tenants_for_current_user.include?(tenant.kb_tenant_id) }
    end

    def edit
      @allowed_user = Kaui::AllowedUser.find(params.require(:id))
      @is_killbill_managed = killbill_managed?(@allowed_user, options_for_klient)

      @roles = roles_for_user(@allowed_user)
    end

    def update
      @allowed_user = Kaui::AllowedUser.find(params.require(:id))

      @allowed_user.description = params[:allowed_user][:description].presence

      @allowed_user.update_in_kb!(params[:password].presence,
                                  params[:roles].blank? ? nil : params[:roles].split(','),
                                  current_user.kb_username,
                                  params[:reason],
                                  params[:comment],
                                  options_for_klient)

      redirect_to kaui_engine.admin_allowed_user_path(@allowed_user.id), notice: 'User was successfully updated'
    end

    def destroy
      allowed_user = Kaui::AllowedUser.find(params.require(:id))

      if allowed_user
        # Delete locally and in KB
        allowed_user.destroy_in_kb!(current_user.kb_username, params[:reason], params[:comment], options_for_klient)
        redirect_to kaui_engine.admin_allowed_users_path, notice: 'User was successfully deleted'
      else
        flash[:error] = "User #{params.require(:id)} not found"
        redirect_to kaui_engine.admin_allowed_users_path
      end
    end

    def add_tenant
      allowed_user = Kaui::AllowedUser.find(params.require(:allowed_user).require(:id))

      unless current_user.root?
        redirect_to admin_allowed_user_path(allowed_user.id), alert: 'Only the root user can set tenants for user'
        return
      end

      tenants = []
      params.each do |tenant, _|
        tenant_info = tenant.split('_')
        next if (tenant_info.size != 2) || (tenant_info[0] != 'tenant')

        tenants << tenant_info[1]
      end

      tenants_for_current_user = retrieve_tenants_for_current_user
      tenants = (Kaui::Tenant.where(id: tenants).select { |tenant| tenants_for_current_user.include?(tenant.kb_tenant_id) }).map(&:id)

      allowed_user.kaui_tenant_ids = tenants

      redirect_to admin_allowed_user_path(allowed_user.id), notice: 'Successfully set tenants for user'
    end

    private

    # this will check if the user is managed by killbill (not managed externally or internally by a shiro config file).
    def killbill_managed?(allowed_user, options = {})
      begin
        Kaui::UserRole.find_roles_by_username(allowed_user.kb_username, options)
      rescue KillBillClient::API::ClientError => _e
        return false
      end

      true
    end

    def allowed_user_params
      allowed_user = params.require(:allowed_user)
      allowed_user.require(:kb_username)
      allowed_user.permit!
    end

    def roles_for_user(allowed_user)
      Kaui::UserRole.find_roles_by_username(allowed_user.kb_username, options_for_klient).map(&:presence).compact
    rescue StandardError
      []
    end
  end
end
