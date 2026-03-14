# frozen_string_literal: true

module Kaui
  class RoleDefinitionsController < Kaui::EngineController
    def new
      @role_definition = Kaui::RoleDefinition.new

      # Store user form context if coming from user creation/edit
      if params[:return_to_user].present?
        session[:role_return_context] = {
          kb_username: params[:kb_username],
          description: params[:description],
          roles: params[:roles],
          external: params[:external],
          allowed_user_id: params[:allowed_user_id]
        }
      end
    end

    def create
      # Sanity is done on the server side
      @role_definition = Kaui::RoleDefinition.new(params.require(:role_definition))
      @role_definition.permissions = @role_definition.permissions.split(',')

      begin
        @role_definition = @role_definition.create(current_user.kb_username, params[:reason], params[:comment], options_for_klient)

        # Check if we need to return to user form with the new role
        return_context = session.delete(:role_return_context)
        if return_context.present?
          # Add the new role to the existing roles
          existing_roles = return_context[:roles].to_s.split(',').reject(&:blank?)
          existing_roles << @role_definition.role unless existing_roles.include?(@role_definition.role)
          return_context[:roles] = existing_roles.join(',')

          # Redirect back to user form (new or edit)
          if return_context[:allowed_user_id].present? && return_context[:allowed_user_id] != ''
            redirect_to edit_admin_allowed_user_path(return_context[:allowed_user_id], user_context: return_context),
                        notice: "Role '#{@role_definition.role}' was successfully created"
          else
            redirect_to new_admin_allowed_user_path(user_context: return_context),
                        notice: "Role '#{@role_definition.role}' was successfully created"
          end
        else
          redirect_to admin_allowed_users_path, notice: 'Role was successfully created'
        end
      rescue StandardError => e
        flash.now[:error] = "Error while creating role: #{as_string(e)}"
        render action: :new
      end
    end
  end
end
