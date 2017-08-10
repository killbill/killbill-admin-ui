require 'symmetric-encryption'

module Kaui
  class Tenant < ApplicationRecord

    attr_encrypted :api_secret

    has_many :kaui_allowed_user_tenants, :class_name => 'Kaui::AllowedUserTenant', :foreign_key => 'kaui_tenant_id'
    has_many :kaui_allowed_users, :through => :kaui_allowed_user_tenants, :source => :kaui_allowed_user

  end
end
