# frozen_string_literal: true

module Kaui
  class Ability
    include CanCan::Ability

    def initialize(user)
      if Kaui.demo_mode
        # Show the links, the server will enforce permissions
        can :manage, :all
        return
      end

      # user is a Kaui::User object (from Devise)
      user.permissions.each do |permission|
        # permission is something like invoice:item_adjust or payment:refund
        # We rely on a naming convention where the left part refers to a Kaui model
        model, action = permission_to_model_action(permission)
        if (model == '*') && (action == '*')
          # All permissions!
          can :manage, :all
        elsif (model == '*') && (action != '*')
          # TODO
        elsif action == '*'
          # TODO: Not sure the :all is really working (but we don't use it)
          begin
            can :all, "Kaui::#{model.camelize}".constantize
          rescue StandardError
            nil
          end
        else
          begin
            can action.to_sym, "Kaui::#{model.camelize}".constantize
          rescue StandardError
            nil
          end
        end
      end
    rescue KillBillClient::API::Unauthorized => _e
      nil
    end

    def permission_to_model_action(permission)
      #
      # Permissions are defined in Kill Kill apis (https://github.com/killbill/killbill-api/blob/master/src/main/java/org/killbill/billing/security/Permission.java)
      # and they look something like 'invoice:item_adjust' or 'payment:refund', where the first part is the Kill Bill module and the second the action.
      #
      # For most of those the Kill Bill module maps to the Kaui model, but for a few, the naming convention breaks, so in order to keep the API clean, we do the fix up
      # in KAUI itself:
      #
      to_be_model, action = permission.split(':')
      # Currently the only actions implemented for overdue and catalog (upload_config) are those implemented at the tenant level:
      to_be_model = 'admin_tenant' if %w[tenant overdue catalog].include?(to_be_model)
      to_be_model = 'subscription' if to_be_model == 'entitlement'

      [to_be_model, action]
    end
  end
end
