# frozen_string_literal: true

module Kaui
  class RoleDefinitionsController < Kaui::EngineController
    DEFAULT_PAGE_SIZE = 20

    def index
      @search_query = params[:q]
      @offset = params[:offset] || 0
      @limit = params[:limit] || DEFAULT_PAGE_SIZE

      # The roles are paginated and searched on the server (see #pagination), this only checks that listing is supported
      @max_nb_records = all_role_definitions.size
    rescue StandardError => e
      @max_nb_records = 0
      if e.is_a?(KillBillClient::API::ClientError) && [404, 405].include?(e.response.code.to_i)
        # Listing roles requires Kill Bill 0.25+
        @list_unsupported = true
      else
        flash.now[:error] = "Error while retrieving roles: #{as_string(e)}"
      end
    end

    def pagination
      searcher = lambda do |search_key, offset, limit|
        all = all_role_definitions
        matching = filter_role_definitions(all, search_key)
        page = matching.slice(offset, limit) || []
        max_nb_records = all.size
        total_nb_records = matching.size
        page.define_singleton_method(:pagination_max_nb_records) { max_nb_records }
        page.define_singleton_method(:pagination_total_nb_records) { total_nb_records }
        page
      end

      data_extractor = lambda do |role_definition, column|
        [
          role_definition.role,
          Array(role_definition.permissions).join(', ')
        ][column]
      end

      formatter = lambda do |role_definition|
        edit_path = view_context.edit_role_definition_path(role_definition.role)
        [
          view_context.link_to(role_definition.role, edit_path),
          Array(role_definition.permissions).join(', '),
          view_context.link_to('Edit', edit_path, class: 'kaui-button edit-button custom-hover text-decoration-none')
        ]
      end

      paginate searcher, data_extractor, formatter
    end

    def new
      @role_definition = Kaui::RoleDefinition.new

      # Store user form context if coming from user creation/edit
      return if params[:return_to_user].blank?

      session[:role_return_context] = {
        kb_username: params[:kb_username],
        description: params[:description],
        roles: params[:roles],
        external: params[:external],
        allowed_user_id: params[:allowed_user_id]
      }
    end

    def edit
      @role_definition = Kaui::RoleDefinition.find_by_name(params.require(:id), options_for_klient)

      # Kill Bill answers 200 with no permissions for a role that does not exist
      if Array(@role_definition.permissions).empty?
        redirect_to role_definitions_path, flash: { error: "Role '#{params[:id]}' was not found" }
        return
      end

      @role_definition.permissions = Array(@role_definition.permissions).join(',')
    rescue StandardError => e
      redirect_to role_definitions_path, flash: { error: "Error while retrieving role: #{as_string(e)}" }
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
          existing_roles = return_context[:roles].to_s.split(',').compact_blank
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

    def update
      @role_definition = Kaui::RoleDefinition.new(role: params.require(:id),
                                                  permissions: params.require(:role_definition)[:permissions].to_s.split(',').map(&:strip).compact_blank)

      begin
        @role_definition.update(current_user.kb_username, params[:reason], params[:comment], options_for_klient)
        redirect_to role_definitions_path, notice: "Role '#{@role_definition.role}' was successfully updated"
      rescue StandardError => e
        @role_definition.permissions = @role_definition.permissions.join(',')
        flash.now[:error] = "Error while updating role: #{as_string(e)}"
        render action: :edit
      end
    end

    private

    def all_role_definitions
      Kaui::RoleDefinition.find_all(options_for_klient).sort_by { |role_definition| role_definition.role.to_s }
    end

    # Case-insensitive match on the role name or any of its permissions
    def filter_role_definitions(role_definitions, search_key)
      return role_definitions if search_key.blank?

      needle = search_key.to_s.downcase
      role_definitions.select do |role_definition|
        role_definition.role.to_s.downcase.include?(needle) || Array(role_definition.permissions).any? { |permission| permission.to_s.downcase.include?(needle) }
      end
    end
  end
end
