require 'killbill_client/api/errors'

module KillBillClient
  module Model
    class Transaction < PaymentTransactionAttributes

      include KillBillClient::Model::CustomFieldHelper
      include KillBillClient::Model::AuditLogWithHistoryHelper
      include KillBillClient::Model::TagHelper

      KILLBILL_API_TRANSACTIONS_PREFIX = "#{KILLBILL_API_PREFIX}/paymentTransactions"

      has_many :properties, KillBillClient::Model::PluginPropertyAttributes
      has_many :audit_logs, KillBillClient::Model::AuditLog

      has_audit_logs_with_history KILLBILL_API_TRANSACTIONS_PREFIX, :transaction_id
      has_custom_fields KILLBILL_API_TRANSACTIONS_PREFIX, :transaction_id
      has_tags KILLBILL_API_TRANSACTIONS_PREFIX, :transaction_id

      def auth(account_id, payment_method_id = nil, user = nil, reason = nil, comment = nil, options = {}, refresh_options = nil)
        @transaction_type = 'AUTHORIZE'
        query_map = {}
        create_initial_transaction("#{Account::KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/payments", query_map, payment_method_id, user, reason, comment, options, refresh_options)
      end

      def purchase(account_id, payment_method_id = nil, user = nil, reason = nil, comment = nil, options = {}, refresh_options = nil)
        @transaction_type = 'PURCHASE'
        query_map = {}
        create_initial_transaction("#{Account::KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/payments", query_map, payment_method_id, user, reason, comment, options, refresh_options)
      end

      def credit(account_id, payment_method_id = nil, user = nil, reason = nil, comment = nil, options = {}, refresh_options = nil)
        @transaction_type = 'CREDIT'
        query_map = {}
        create_initial_transaction("#{Account::KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/payments", query_map, payment_method_id, user, reason, comment, options, refresh_options)
      end

      def auth_by_external_key(account_external_key, payment_method_id = nil, user = nil, reason = nil, comment = nil, options = {}, refresh_options = nil)
        @transaction_type = 'AUTHORIZE'
        query_map = {:externalKey => account_external_key}
        create_initial_transaction("#{Account::KILLBILL_API_ACCOUNTS_PREFIX}/payments", query_map, payment_method_id, user, reason, comment, options, refresh_options)
      end

      def purchase_by_external_key(account_external_key, payment_method_id = nil, user = nil, reason = nil, comment = nil, options = {}, refresh_options = nil)
        @transaction_type = 'PURCHASE'
        query_map = {:externalKey => account_external_key}
        create_initial_transaction("#{Account::KILLBILL_API_ACCOUNTS_PREFIX}/payments", query_map, payment_method_id, user, reason, comment, options, refresh_options)
      end

      def credit_by_external_key(account_external_key, payment_method_id = nil, user = nil, reason = nil, comment = nil, options = {}, refresh_options = nil)
        @transaction_type = 'CREDIT'
        query_map = {:externalKey => account_external_key}
        create_initial_transaction("#{Account::KILLBILL_API_ACCOUNTS_PREFIX}/payments", query_map, payment_method_id, user, reason, comment, options, refresh_options)
      end

      def complete(user = nil, reason = nil, comment = nil, options = {}, refresh_options = nil)
        complete_initial_transaction(user, reason, comment, options, refresh_options)
      end

      def complete_auth(user = nil, reason = nil, comment = nil, options = {}, refresh_options = nil)
        @transaction_type = 'AUTHORIZE'
        complete_initial_transaction(user, reason, comment, options, refresh_options)
      end

      def complete_purchase(user = nil, reason = nil, comment = nil, options = {}, refresh_options = nil)
        @transaction_type = 'PURCHASE'
        complete_initial_transaction(user, reason, comment, options, refresh_options)
      end

      def complete_credit(user = nil, reason = nil, comment = nil, options = {}, refresh_options = nil)
        @transaction_type = 'CREDIT'
        complete_initial_transaction(user, reason, comment, options, refresh_options)
      end

      def capture(user = nil, reason = nil, comment = nil, options = {}, refresh_options = nil)
        follow_location = delete_follow_location(options)
        refresh_payment_with_failure_handling(follow_location, refresh_options || options) do
          self.class.post "#{follow_up_path(payment_id)}",
                          to_json,
                          {},
                          {
                              :user    => user,
                              :reason  => reason,
                              :comment => comment,
                          }.merge(options)
        end
      end

      def refund(user = nil, reason = nil, comment = nil, options = {}, refresh_options = nil)
        follow_location = delete_follow_location(options)
        refresh_payment_with_failure_handling(follow_location, refresh_options || options) do
          self.class.post "#{follow_up_path(payment_id)}/refunds",
                          to_json,
                          {},
                          {
                              :user    => user,
                              :reason  => reason,
                              :comment => comment,
                          }.merge(options)
        end
      end

      def refund_by_external_key(user = nil, reason = nil, comment = nil, options = {}, refresh_options = nil)
        follow_location = delete_follow_location(options)
        refresh_payment_with_failure_handling(follow_location, refresh_options || options) do
          self.class.post "#{Payment::KILLBILL_API_PAYMENTS_PREFIX}/refunds",
                          to_json,
                          {},
                          {
                              :user    => user,
                              :reason  => reason,
                              :comment => comment,
                          }.merge(options)
        end
      end

      def void(user = nil, reason = nil, comment = nil, options = {}, refresh_options = nil)
        follow_location = delete_follow_location(options)
        refresh_payment_with_failure_handling(follow_location, refresh_options || options) do
          self.class.delete "#{follow_up_path(payment_id)}",
                            to_json,
                            {},
                            {
                                :user    => user,
                                :reason  => reason,
                                :comment => comment,
                            }.merge(options)
          if payment_external_key
            KillBillClient::Model::Payment.find_by_external_key(payment_external_key, false, false, options)
          else
            KillBillClient::Model::Payment.find_by_id(payment_id, false, false, options)
          end
        end
      end

      def chargeback(user = nil, reason = nil, comment = nil, options = {}, refresh_options = nil)
        follow_location = delete_follow_location(options)
        refresh_payment_with_failure_handling(follow_location, refresh_options || options) do
          self.class.post "#{follow_up_path(payment_id)}/chargebacks",
                          to_json,
                          {},
                          {
                              :user    => user,
                              :reason  => reason,
                              :comment => comment,
                          }.merge(options)
        end
      end


      def cancel_scheduled_payment(user = nil, reason = nil, comment = nil, options = {})

        uri = transaction_external_key ? "#{Payment::KILLBILL_API_PAYMENTS_PREFIX}/cancelScheduledPaymentTransaction" :
            "#{Payment::KILLBILL_API_PAYMENTS_PREFIX}/#{transaction_id}/cancelScheduledPaymentTransaction"

        query_map = {}
        query_map[:transactionExternalKey] = transaction_external_key if transaction_external_key
        self.class.delete uri,
                          {},
                          query_map,
                          {
                              :user    => user,
                              :reason  => reason,
                              :comment => comment,
                          }.merge(options)
      end

      def chargeback_by_external_key(user = nil, reason = nil, comment = nil, options = {}, refresh_options = nil)
        follow_location = delete_follow_location(options)
        refresh_payment_with_failure_handling(follow_location, refresh_options || options) do
        self.class.post "#{follow_up_path(payment_id)}/chargebacks",
                        to_json,
                        {},
                        {
                            :user    => user,
                            :reason  => reason,
                            :comment => comment,
                        }.merge(options)
          end
      end

      def chargeback_reversals(user = nil, reason = nil, comment = nil, options = {}, refresh_options = nil)
        follow_location = delete_follow_location(options)
        refresh_payment_with_failure_handling(follow_location, refresh_options || options) do
        self.class.post "#{follow_up_path(payment_id)}/chargebackReversals",
                        to_json,
                        {},
                        {
                            :user    => user,
                            :reason  => reason,
                            :comment => comment,
                        }.merge(options)
          end
      end

      def update_transaction_state(status, control_plugin_name = nil, user, reason, comment, options)
        self.class.post "KILLBILL_API_TRANSACTIONS_PREFIX/#{transaction_id}",
                       {:paymentId => payment_id, :status => status}.to_json,
                       {:controlPluginName => (control_plugin_name || [])},
                       {
                          :user => user,
                          :reason => reason,
                          :comment => comment
                       }.merge(options)
      end

      private


      def follow_up_path(payment_id)
        path = Payment::KILLBILL_API_PAYMENTS_PREFIX
        path += "/#{payment_id}" unless payment_id.nil?
        path
      end

      def create_initial_transaction(path, query_map, payment_method_id, user, reason, comment, options, refresh_options)
        query_map[:paymentMethodId] = payment_method_id unless payment_method_id.nil?

        follow_location = delete_follow_location(options)
        refresh_payment_with_failure_handling(follow_location, refresh_options || options) do
          self.class.post path,
                          to_json,
                          query_map,
                          {
                              :user => user,
                              :reason => reason,
                              :comment => comment
                          }.merge(options)
        end
      end

      def complete_initial_transaction(user, reason, comment, options, refresh_options)
        follow_location = delete_follow_location(options)
        refresh_payment_with_failure_handling(follow_location, refresh_options || options) do
          self.class.put follow_up_path(payment_id),
                         to_json,
                         {},
                         {
                             :user => user,
                             :reason => reason,
                             :comment => comment
                         }.merge(options)
          if payment_external_key
            KillBillClient::Model::Payment.find_by_external_key(payment_external_key, false, false, options)
          else
            KillBillClient::Model::Payment.find_by_id(payment_id, false, false, options)
          end
        end
      end

      def delete_follow_location(options, key = :follow_location, default_value = true)
        if options.has_key?(key)
          return options.delete(key)
        end

        default_value
      end

      def refresh_payment_with_failure_handling(follow_location, refresh_options)
        begin
          created_transaction = yield
        rescue KillBillClient::API::ResponseError => error
          response = error.response
          if follow_location && response['location']
            created_transaction = Transaction.new
            created_transaction.uri = response['location']
          else
            raise error
          end
        end

        if follow_location
          return created_transaction.refresh(refresh_options, Payment)
        end

        created_payment = Payment.new
        created_payment.uri = created_transaction.uri
        created_payment
      end
    end
  end
end
