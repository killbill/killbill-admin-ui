# frozen_string_literal: true

module Kaui
  module AdminAllowedUsersHelper
    # Check if a user can be deleted
    # Returns false if the user is an admin or the current logged-in user
    def can_delete_user?(user, user_roles)
      is_admin = user_roles.include?('admin') || user.kb_username == Kaui.root_username
      is_current_user = user.kb_username == current_user.kb_username

      !is_admin && !is_current_user
    end
  end
end
