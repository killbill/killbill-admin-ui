module Kaui
  class AllowedUser < ActiveRecord::Base
    attr_accessible :kb_username, :description

    has_many :kaui_allowed_user_tenants, :class_name => 'Kaui::AllowedUserTenant', :foreign_key => 'kaui_allowed_user_id'
    has_many :kaui_tenants, :through => :kaui_allowed_user_tenants, :source => :kaui_tenant, :uniq => true
  end
end
