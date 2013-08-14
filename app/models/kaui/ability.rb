module Kaui
  class Ability
    include CanCan::Ability

    def initialize(user)
      # user is a Kaui::User object (from Devise)
      user.permissions.each do |permission|
        # permission is something like invoice:item_adjust or payment:refund
        # We rely on a naming convention where the left part refers to a Kaui model
        model, action = permission.split(':')
        can action.to_sym, ('Kaui::' + model.capitalize).constantize
      end
    rescue KillBillClient::API::Unauthorized => e
    end
  end
end
