module KillBillClient
  module Model
    class BulkSubscription < BulkSubscriptionsBundleAttributes

      include KillBillClient::Model::CustomFieldHelper

      KILLBILL_API_BULK_ENTITLEMENT_PREFIX = "#{KILLBILL_API_PREFIX}/subscriptions/createSubscriptionsWithAddOns"

      has_many :base_entitlement_and_add_ons, KillBillClient::Model::SubscriptionAttributes

      class << self

        def create_bulk_subscriptions(bulk_subscription_list, user = nil, reason = nil, comment = nil, entitlement_date = nil, billing_date = nil, call_completion_sec = nil, options = {})

          params = {}
          params[:callCompletion] = true unless call_completion_sec.nil?
          params[:callTimeoutSec] = call_completion_sec unless call_completion_sec.nil?
          params[:entitlementDate]  = entitlement_date unless entitlement_date.nil?
          params[:billingDate]  = billing_date unless billing_date.nil?

          post KILLBILL_API_BULK_ENTITLEMENT_PREFIX,
               bulk_subscription_list.to_json,
               params,
               {
                   :user => user,
                   :reason => reason,
                   :comment => comment,
               }.merge(options)
        end


      end
    end
  end
end


