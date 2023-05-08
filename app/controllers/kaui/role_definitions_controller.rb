# frozen_string_literal: true

module Kaui
  class RoleDefinitionsController < Kaui::EngineController
    def new
      @role_definition = Kaui::RoleDefinition.new
    end

    def create
      # Sanity is done on the server side
      @role_definition = Kaui::RoleDefinition.new(params.require(:role_definition))
      @role_definition.permissions = @role_definition.permissions.split(',')

      begin
        @role_definition = @role_definition.create(current_user.kb_username, params[:reason], params[:comment], options_for_klient)
        redirect_to admin_allowed_users_path, notice: 'Role was successfully created'
      rescue StandardError => e
        flash.now[:error] = "Error while creating role: #{as_string(e)}"
        render action: :new
      end
    end
  end
end
