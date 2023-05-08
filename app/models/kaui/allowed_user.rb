# frozen_string_literal: true

module Kaui
  class AllowedUser < ApplicationRecord
    has_many :kaui_allowed_user_tenants,
             class_name: 'Kaui::AllowedUserTenant',
             foreign_key: 'kaui_allowed_user_id'

    has_many :kaui_tenants, -> { distinct },
             through: :kaui_allowed_user_tenants,
             source: :kaui_tenant

    # Create the user locally and in Kill Bill (if needed)
    def create_in_kb!(password, roles = [], user = nil, reason = nil, comment = nil, options = {})
      # Create in Kill Bill
      kb_user = KillBillClient::Model::UserRoles.new
      kb_user.username = kb_username
      kb_user.password = password
      kb_user.roles = roles

      begin
        kb_user.create(user, reason, comment, options)
      rescue KillBillClient::API::BadRequest => e
        error_code = begin
          JSON.parse(e.response.body)['code']
        rescue StandardError
          nil
        end
        raise e unless error_code == 40_002 # SECURITY_USER_ALREADY_EXISTS
      end

      # Save locally
      save!
    end

    # Update the user locally and in Kill Bill (if needed)
    def update_in_kb!(password, roles, user = nil, reason = nil, comment = nil, options = {})
      user_role = KillBillClient::Model::UserRoles.new
      user_role.username = kb_username

      # We have two different APIs to update password and roles
      unless password.nil?
        user_role.password = password
        user_role.update(user, reason, comment, options)
        user_role.password = nil
      end
      unless roles.nil?
        user_role.roles = roles
        user_role.update(user, reason, comment, options)
      end

      save!
    end

    # Delete the user locally and in Kill Bill (if needed)
    def destroy_in_kb!(user = nil, reason = nil, comment = nil, options = {})
      user_role = KillBillClient::Model::UserRoles.new
      user_role.username = kb_username

      begin
        user_role.destroy(user, reason, comment, options)
      rescue KillBillClient::API::BadRequest => _e
        # User already deactivated in Kill Bill
      end

      # Destroy locally
      destroy!
    end
  end
end
