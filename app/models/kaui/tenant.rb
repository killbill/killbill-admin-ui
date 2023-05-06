# frozen_string_literal: true

require 'symmetric-encryption'

module Kaui
  class Tenant < ApplicationRecord
    attribute :encrypted_api_secret, :encrypted, random_iv: false
    alias_attribute :api_secret, :encrypted_api_secret

    has_many :kaui_allowed_user_tenants, class_name: 'Kaui::AllowedUserTenant', foreign_key: 'kaui_tenant_id'
    has_many :kaui_allowed_users, through: :kaui_allowed_user_tenants, source: :kaui_allowed_user
  end
end
