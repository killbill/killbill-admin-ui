module Kaui
  module PermissionsHelper

    def can_close_account?
      isAuthorizedWhen = true
      isAuthorizedWhen &= can? :cancel, Kaui::Subscription
      isAuthorizedWhen &= can? :pause_resume, Kaui::Subscription
      isAuthorizedWhen &= can? :add, Kaui::Tag
      isAuthorizedWhen &= can? :item_adjust, Kaui::Invoice

      isAuthorizedWhen
    end

  end
end