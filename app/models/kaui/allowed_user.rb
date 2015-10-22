module Kaui
  class AllowedUser < ActiveRecord::Base
    attr_accessible :kb_username, :description

    has_many :kaui_allowed_user_tenants,
             :class_name => 'Kaui::AllowedUserTenant',
             :foreign_key => 'kaui_allowed_user_id'

    has_many :kaui_tenants, -> { uniq },
             :through => :kaui_allowed_user_tenants,
             :source => :kaui_tenant

    def create_in_kb!(password, roles = [], user = nil, reason = nil, comment = nil, options = {})
      # Create in Kill Bill
      kb_user = KillBillClient::Model::UserRoles.new
      kb_user.username = kb_username
      kb_user.password = password
      kb_user.roles = roles
      kb_user.create(user, reason, comment, options)

      # Save locally
      save!
    end
  end
end
