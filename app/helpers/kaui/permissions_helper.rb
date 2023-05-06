# frozen_string_literal: true

module Kaui
  module PermissionsHelper
    def can_close_account?
      is_authorized_when = true
      is_authorized_when &= can? :cancel, Kaui::Subscription
      is_authorized_when &= can? :pause_resume, Kaui::Subscription
      is_authorized_when &= can? :add, Kaui::Tag
      is_authorized_when &= can? :item_adjust, Kaui::Invoice

      is_authorized_when
    end
  end
end
