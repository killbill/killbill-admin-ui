# frozen_string_literal: true

module Kaui
  class AllowedUserTenant < ApplicationRecord
    belongs_to :kaui_allowed_user, class_name: 'Kaui::AllowedUser'
    belongs_to :kaui_tenant, class_name: 'Kaui::Tenant'
  end
end
