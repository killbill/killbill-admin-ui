module KillBillClient
  module Model
    class Payment < PaymentAttributes

      include KillBillClient::Model::CustomFieldHelper
      include KillBillClient::Model::TagHelper
      include KillBillClient::Model::AuditLogWithHistoryHelper

      KILLBILL_API_PAYMENTS_PREFIX = "#{KILLBILL_API_PREFIX}/payments"

      has_many :transactions, KillBillClient::Model::Transaction
      has_many :payment_attempts, KillBillClient::Model::PaymentAttemptAttributes
      has_many :audit_logs, KillBillClient::Model::AuditLog

      has_custom_fields KILLBILL_API_PAYMENTS_PREFIX, :payment_id
      has_tags KILLBILL_API_PAYMENTS_PREFIX, :payment_id
      has_audit_logs_with_history KILLBILL_API_PAYMENTS_PREFIX, :payment_id

      class << self
        def find_by_id(payment_id, with_plugin_info = false, with_attempts = false, options = {})
          get "#{KILLBILL_API_PAYMENTS_PREFIX}/#{payment_id}",
              {
                  :withAttempts => with_attempts,
                  :withPluginInfo => with_plugin_info
              },
              options
        end

        def find_by_external_key(external_key, with_plugin_info = false, with_attempts = false, options = {})
          get "#{KILLBILL_API_PAYMENTS_PREFIX}",
              {
                  :externalKey => external_key,
                  :withAttempts => with_attempts,
                  :withPluginInfo => with_plugin_info
              },
              options
        end

        def find_by_transaction_id(transaction_id, with_plugin_info = false, with_attempts = false, plugin_property = [], audit = 'NONE', options = {})
          get "#{Transaction::KILLBILL_API_TRANSACTIONS_PREFIX}/#{transaction_id}",
              {
                  :withPluginInfo => with_plugin_info,
                  :withAttempts => with_attempts,
                  :pluginProperty => plugin_property,
                  :audit => audit
              },
              options
        end

        def find_by_transaction_external_key(external_key, with_plugin_info = false, with_attempts = false, plugin_property = [], audit = 'NONE', options = {})
          get "#{Transaction::KILLBILL_API_TRANSACTIONS_PREFIX}",
              {
                  :transactionExternalKey => external_key,
                  :withPluginInfo => with_plugin_info,
                  :withAttempts => with_attempts,
                  :pluginProperty => plugin_property,
                  :audit => audit
              },
              options
        end

        def find_in_batches(offset = 0, limit = 100, options = {})
          get "#{KILLBILL_API_PAYMENTS_PREFIX}/#{Resource::KILLBILL_API_PAGINATION_PREFIX}",
              {
                  :offset => offset,
                  :limit  => limit
              },
              options
        end

        def find_in_batches_by_search_key(search_key, offset = 0, limit = 100, options = {})
          get "#{KILLBILL_API_PAYMENTS_PREFIX}/search/#{search_key}",
              {
                  :offset => offset,
                  :limit  => limit
              },
              options
        end

        def attempt_audit_logs_with_history(payment_attempt_id, options = {})
          get "#{KILLBILL_API_PAYMENTS_PREFIX}/attempts/#{payment_attempt_id}/auditLogsWithHistory",
                         {},
                         options,
                         AuditLog
        end
      end
    end
  end
end
