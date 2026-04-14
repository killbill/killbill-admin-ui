module KillBillClient
  module Model
    class Bundle < BundleAttributes

      KILLBILL_API_BUNDLES_PREFIX = "#{KILLBILL_API_PREFIX}/bundles"

      include KillBillClient::Model::TagHelper
      include KillBillClient::Model::CustomFieldHelper
      include KillBillClient::Model::AuditLogWithHistoryHelper

      has_custom_fields KILLBILL_API_BUNDLES_PREFIX, :bundle_id
      has_tags KILLBILL_API_BUNDLES_PREFIX, :bundle_id

      has_many :subscriptions, KillBillClient::Model::Subscription
      has_many :audit_logs, KillBillClient::Model::AuditLog
      has_audit_logs_with_history KILLBILL_API_BUNDLES_PREFIX, :bundle_id

      class << self
        def find_in_batches(offset = 0, limit = 100, options = {})
          get "#{KILLBILL_API_BUNDLES_PREFIX}/#{Resource::KILLBILL_API_PAGINATION_PREFIX}",
              {
                  :offset => offset,
                  :limit  => limit
              },
              options
        end

        def find_in_batches_by_search_key(search_key, offset = 0, limit = 100, options = {})
          get "#{KILLBILL_API_BUNDLES_PREFIX}/search/#{search_key}",
              {
                  :offset => offset,
                  :limit  => limit
              },
              options
        end

        def find_by_id(bundle_id, options = {})
          get "#{KILLBILL_API_BUNDLES_PREFIX}/#{bundle_id}",
              {},
              options
        end

        # Return the active one
        def find_by_external_key(external_key, included_deleted, options = {})
          params = {}
          params[:externalKey] = external_key
          params[:includedDeleted] = included_deleted if included_deleted

          result  = get "#{KILLBILL_API_BUNDLES_PREFIX}",
              params,
              options
          return included_deleted ? result : result[0]
        end

        # Return active and inactive ones
        def find_all_by_account_id_and_external_key(account_id, external_key, options = {})
          get "#{Account::KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/bundles?externalKey=#{external_key}",
              {},
              options
        end

      end

      # Transfer the bundle to the new account. The new account_id should be set in this object
      def transfer(requested_date = nil, billing_policy = nil, user = nil, reason = nil, comment = nil, options = {})
        params                 = {}
        params[:requestedDate] = requested_date unless requested_date.nil?
        params[:billingPolicy] = billing_policy unless billing_policy.nil?

        result                 = self.class.post "#{KILLBILL_API_BUNDLES_PREFIX}/#{bundle_id}",
                                                to_json,
                                                params,
                                                {
                                                    :user    => user,
                                                    :reason  => reason,
                                                    :comment => comment,
                                                }.merge(options)

        result.refresh(options)
      end

      # Pause the bundle (and all its subscription)
      def pause(requested_date = nil, user = nil, reason = nil, comment = nil, options = {})

        params                 = {}
        params[:requestedDate] = requested_date unless requested_date.nil?
        self.class.put "#{KILLBILL_API_BUNDLES_PREFIX}/#{@bundle_id}/pause",
                       {},
                       params,
                       {
                           :user    => user,
                           :reason  => reason,
                           :comment => comment,
                       }.merge(options)
      end

      # Resume the bundle (and all its subscription)
      def resume(requested_date = nil, user = nil, reason = nil, comment = nil, options = {})

        params                 = {}
        params[:requestedDate] = requested_date unless requested_date.nil?
        self.class.put "#{KILLBILL_API_BUNDLES_PREFIX}/#{@bundle_id}/resume",
                       {},
                       params,
                       {
                           :user    => user,
                           :reason  => reason,
                           :comment => comment,
                       }.merge(options)
      end



      # Low level api to block/unblock a given subscription/bundle/account
      def set_blocking_state(state_name, service, is_block_change, is_block_entitlement, is_block_billing, requested_date = nil, user = nil, reason = nil, comment = nil, options = {})

        params                 = {}
        params[:requestedDate] = requested_date unless requested_date.nil?

        body = KillBillClient::Model::BlockingStateAttributes.new
        body.state_name = state_name
        body.service = service
        body.is_block_change = is_block_change
        body.is_block_entitlement = is_block_entitlement
        body.is_block_billing = is_block_billing

        self.class.post "#{KILLBILL_API_BUNDLES_PREFIX}/#{@bundle_id}/block",
                       body.to_json,
                       params,
                       {
                           :user    => user,
                           :reason  => reason,
                           :comment => comment,
                       }.merge(options)
      end

      def rename_external_key(user = nil, reason = nil, comment = nil, options = {})

        self.class.put "#{KILLBILL_API_BUNDLES_PREFIX}/#{@bundle_id}/renameKey",
                       to_json,
                       {},
                       {
                           :user    => user,
                           :reason  => reason,
                           :comment => comment,
                       }.merge(options)
      end

    end
  end
end
