module KillBillClient
  module Model
    class Subscription < SubscriptionAttributes

      include KillBillClient::Model::TagHelper
      include KillBillClient::Model::CustomFieldHelper
      include KillBillClient::Model::AuditLogWithHistoryHelper

      KILLBILL_API_ENTITLEMENT_PREFIX = "#{KILLBILL_API_PREFIX}/subscriptions"

      has_many :events, KillBillClient::Model::EventSubscription
      has_many :price_overrides, KillBillClient::Model::PhasePriceAttributes
      has_many :audit_logs, KillBillClient::Model::AuditLog

      has_custom_fields KILLBILL_API_ENTITLEMENT_PREFIX, :subscription_id
      has_tags KILLBILL_API_ENTITLEMENT_PREFIX, :subscription_id

      has_audit_logs_with_history KILLBILL_API_ENTITLEMENT_PREFIX, :subscription_id

      class << self
        def find_by_id(subscription_id, audit = "NONE", options = {})
          get "#{KILLBILL_API_ENTITLEMENT_PREFIX}/#{subscription_id}",
              {
                :audit     => audit
              },
              options
        end

        def find_by_external_key(external_key, audit = "NONE", options = {})
          get "#{KILLBILL_API_ENTITLEMENT_PREFIX}",
              {
                :externalKey     => external_key,
                :audit     => audit
              },
              options
        end


        def event_audit_logs_with_history(event_id, options = {})
          get "#{KILLBILL_API_ENTITLEMENT_PREFIX}/events/#{event_id}/auditLogsWithHistory",
              {},
              options,
              AuditLog
        end

      end
      #
      # Create a new entitlement
      #
      #
      #
      def create(user = nil, reason = nil, comment = nil, requested_date = nil, call_completion = false, options = {})

        params                  = {}
        params[:callCompletion] = call_completion
        params[:entitlementDate]  = requested_date unless requested_date.nil?
        params[:billingDate]  = requested_date unless requested_date.nil?


        created_entitlement = self.class.post KILLBILL_API_ENTITLEMENT_PREFIX,
                                              to_json,
                                              params,
                                              {
                                                  :user    => user,
                                                  :reason  => reason,
                                                  :comment => comment,
                                              }.merge(options)
        created_entitlement.refresh(options)
      end

      #
      # Change the plan of the existing Entitlement
      #
      # @input : the hash with the new product info { product_name, billing_period, price_list}
      # @requested_date : the date when that change should occur
      # @billing_policy : the override for the billing policy {END_OF_TERM, IMMEDIATE}
      # @ call_completion : whether the call should wait for invoice/payment to be completed before calls return
      #
      def change_plan(input, user = nil, reason = nil, comment = nil,
                      requested_date = nil, billing_policy = nil, target_phase_type = nil, call_completion = false, options = {})

        params                  = {}
        params[:callCompletion] = call_completion
        params[:requestedDate]  = requested_date unless requested_date.nil?
        params[:billingPolicy]  = billing_policy unless billing_policy.nil?

        # Make sure account_id is set
        input[:accountId] = @account_id
        input[:productCategory] = @product_category
        input[:phaseType] = target_phase_type

        self.class.put "#{KILLBILL_API_ENTITLEMENT_PREFIX}/#{@subscription_id}",
                       input.to_json,
                       params,
                       {
                           :user    => user,
                           :reason  => reason,
                           :comment => comment,
                       }.merge(options)
        self.class.find_by_id(@subscription_id, "NONE", options)
      end

      #
      # Cancel the entitlement at the requested date
      #
      # @requested_date : the date when that change should occur
      # @billing_policy : the override for the billing policy {END_OF_TERM, IMMEDIATE}
      #
      def cancel(user = nil, reason = nil, comment = nil, requested_date = nil, entitlementPolicy = nil, billing_policy = nil, use_requested_date_for_billing = nil, options = {})
        params                              = {}
        params[:requestedDate]              = requested_date unless requested_date.nil?
        params[:billingPolicy]              = billing_policy unless billing_policy.nil?
        params[:entitlementPolicy]          = entitlementPolicy unless entitlementPolicy.nil?
        params[:useRequestedDateForBilling] = use_requested_date_for_billing unless use_requested_date_for_billing.nil?

        self.class.delete "#{KILLBILL_API_ENTITLEMENT_PREFIX}/#{subscription_id}",
                          {},
                          params,
                          {
                              :user    => user,
                              :reason  => reason,
                              :comment => comment,
                          }.merge(options)
      end

      #
      # Uncancel a future cancelled entitlement
      #
      def uncancel(user = nil, reason = nil, comment = nil, options = {})
        params = {}
        self.class.put "#{KILLBILL_API_ENTITLEMENT_PREFIX}/#{subscription_id}/uncancel",
                       nil,
                       params,
                       {
                           :user    => user,
                           :reason  => reason,
                           :comment => comment,
                       }.merge(options)
      end

      #
      # Update Subscription BCD
      #
      def update_bcd(user = nil, reason = nil, comment = nil, effective_from_date = nil, force_past_effective_date = nil, options = {})

        params                  = {}
        params[:effectiveFromDate] = effective_from_date unless effective_from_date.nil?
        params[:forceNewBcdWithPastEffectiveDate] = force_past_effective_date unless force_past_effective_date.nil?

        return self.class.put "#{KILLBILL_API_ENTITLEMENT_PREFIX}/#{subscription_id}/bcd",
                              self.to_json,
                              params,
                              {
                                  :user    => user,
                                  :reason  => reason,
                                  :comment => comment,
                              }.merge(options)
      end


      #
      # Block a Subscription
      #
      def set_blocking_state(state_name, service, is_block_change, is_block_entitlement, is_block_billing, requested_date = nil, user = nil, reason = nil, comment = nil, options = {})

        body = KillBillClient::Model::BlockingStateAttributes.new
        body.state_name = state_name
        body.service = service
        body.is_block_change = is_block_change
        body.is_block_entitlement = is_block_entitlement
        body.is_block_billing = is_block_billing
        body.type = "SUBSCRIPTION"

        params = {}
        params[:requestedDate] = requested_date unless requested_date.nil?

        self.class.post "#{KILLBILL_API_ENTITLEMENT_PREFIX}/#{subscription_id}/block",
                       body.to_json,
                       params,
                       {
                           :user    => user,
                           :reason  => reason,
                           :comment => comment,
                       }.merge(options)
      end

      #
      # Create an entitlement with addOn products
      #
      def create_entitlement_with_add_on(entitlements, entitlement_date, billing_date, migrated = false, rename_key_if_exists_and_unused = true, call_completion_sec = nil, user = nil, reason = nil, comment = nil, options = {})
        params = {}
        params[:entitlementDate] = entitlement_date if entitlement_date
        params[:billingDate] = billing_date if billing_date
        params[:migrated] = migrated
        params[:renameKeyIfExistsAndUnused] = rename_key_if_exists_and_unused
        params[:callCompletion] = true unless call_completion_sec.nil?
        params[:callTimeoutSec] = call_completion_sec unless call_completion_sec.nil?

        self.class.post "#{KILLBILL_API_ENTITLEMENT_PREFIX}/createSubscriptionWithAddOns",
                        entitlements.to_json,
                        params,
                        {
                            :user    => user,
                            :reason  => reason,
                            :comment => comment,
                        }.merge(options)
      end

      #
      # Undo a pending change plan on an entitlement
      #
      def undo_change_plan(user = nil, reason = nil, comment = nil, options = {})

        self.class.put "#{KILLBILL_API_ENTITLEMENT_PREFIX}/#{subscription_id}/undoChangePlan",
                       {},
                       {},
                       {
                           :user    => user,
                           :reason  => reason,
                           :comment => comment,
                       }.merge(options)
      end

      #
      # Update Subscription Quantity
      #
      def update_quantity(user = nil, reason = nil, comment = nil, effective_from_date = nil, force_new_quantity_with_past_effective_date = nil, options = {})
        params                  = {}
        params[:effectiveFromDate] = effective_from_date unless effective_from_date.nil?
        params[:forceNewQuantityWithPastEffectiveDate] = force_new_quantity_with_past_effective_date unless force_new_quantity_with_past_effective_date.nil?

        return self.class.put "#{KILLBILL_API_ENTITLEMENT_PREFIX}/#{subscription_id}/quantity",
                              self.to_json,
                              params,
                              {
                                  :user    => user,
                                  :reason  => reason,
                                  :comment => comment,
                              }.merge(options)
      end
    end
  end
end
