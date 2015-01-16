module Kaui
  class AllowedUserTenant < ActiveRecord::Base
    belongs_to :kaui_allowed_user, :class_name => 'Kaui::AllowedUser', :foreign_key => 'kaui_allowed_user_id'
    belongs_to :kaui_tenant, :class_name => 'Kaui::Tenant', :foreign_key => 'kaui_tenant_id'
  end
end