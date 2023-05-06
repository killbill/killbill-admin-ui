# frozen_string_literal: true

module Kaui
  class Subscription < KillBillClient::Model::Subscription
    def cancel_entitlement_immediately(user = nil, reason = nil, comment = nil, options = {})
      requested_date                 = nil
      entitlement_policy             = 'IMMEDIATE'
      billing_policy                 = nil
      use_requested_date_for_billing = true
      cancel(user, reason, comment, requested_date, entitlement_policy, billing_policy, use_requested_date_for_billing, options)
    end
  end
end
