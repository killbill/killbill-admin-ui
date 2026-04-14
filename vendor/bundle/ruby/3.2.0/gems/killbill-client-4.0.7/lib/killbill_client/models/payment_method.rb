module KillBillClient
  module Model
    class PaymentMethod < PaymentMethodAttributes

      include KillBillClient::Model::CustomFieldHelper
      include KillBillClient::Model::AuditLogWithHistoryHelper

      KILLBILL_API_PAYMENT_METHODS_PREFIX = "#{KILLBILL_API_PREFIX}/paymentMethods"
      EXTERNAL_PAYMENT = '__EXTERNAL_PAYMENT__'.freeze

      has_many :audit_logs, KillBillClient::Model::AuditLog

      has_audit_logs_with_history KILLBILL_API_PAYMENT_METHODS_PREFIX, :payment_method_id
      has_custom_fields KILLBILL_API_PAYMENT_METHODS_PREFIX, :payment_method_id

      class << self
        def find_by_id(payment_method_id, included_deleted = false, with_plugin_info = false, plugin_property = [], audit = 'NONE', options = {})
          get "#{KILLBILL_API_PAYMENT_METHODS_PREFIX}/#{payment_method_id}",
              {
                  :pluginProperty => plugin_property,
                  :includedDeleted => included_deleted,
                  :audit => audit,
                  :withPluginInfo => with_plugin_info
              },
              options
        end

        def find_all_by_account_id(account_id, with_plugin_info = false, options = {})
          get "#{Account::KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/paymentMethods",
              {
                  :withPluginInfo => with_plugin_info
              },
              options
        end

        def find_in_batches(offset = 0, limit = 100, options = {})
          get "#{KILLBILL_API_PAYMENT_METHODS_PREFIX}/#{Resource::KILLBILL_API_PAGINATION_PREFIX}",
              {
                  :offset => offset,
                  :limit => limit
              },
              options
        end

        def find_in_batches_by_search_key(search_key, offset = 0, limit = 100, options = {})
          get "#{KILLBILL_API_PAYMENT_METHODS_PREFIX}/search/#{search_key}",
              {
                  :offset => offset,
                  :limit => limit
              },
              options
        end

        def find_by_external_key(external_key, included_deleted = false, with_plugin_info = false, plugin_property = [], audit = 'NONE', options = {})
          get "#{KILLBILL_API_PAYMENT_METHODS_PREFIX}",
              {
                  :externalKey => external_key,
                  :pluginProperty => plugin_property,
                  :includedDeleted => included_deleted,
                  :audit => audit,
                  :withPluginInfo => with_plugin_info
              },
              options
        end

        def set_default(payment_method_id, account_id, user = nil, reason = nil, comment = nil, options = {})
          put "#{Account::KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/paymentMethods/#{payment_method_id}/setDefault",
              nil,
              {},
              {
                  :user => user,
                  :reason => reason,
                  :comment => comment,
              }.merge(options)
        end

        def destroy(payment_method_id, set_auto_pay_off = false, force_default_deletion = false, user = nil, reason = nil, comment = nil, options = {})
          delete "#{KILLBILL_API_PAYMENT_METHODS_PREFIX}/#{payment_method_id}",
                 {},
                 {
                     :forceDefaultPmDeletion => force_default_deletion,
                     :deleteDefaultPmWithAutoPayOff => set_auto_pay_off
                 },
                 {
                     :user => user,
                     :reason => reason,
                     :comment => comment,
                 }.merge(options)
        end

        def refresh(account_id, user = nil, reason = nil, comment = nil, options = {})
          put "#{Account::KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/paymentMethods/refresh",
               nil,
               {},
               {
                   :user => user,
                   :reason => reason,
                   :comment => comment,
               }.merge(options)
        end
      end

      def create(is_default, user = nil, reason = nil, comment = nil, options = {})
        created_pm = self.class.post "#{Account::KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/paymentMethods",
                                     to_json,
                                     {
                                         :isDefault => is_default
                                     },
                                     {
                                         :user => user,
                                         :reason => reason,
                                         :comment => comment,
                                     }.merge(options)
        created_pm.refresh(options)
      end


      def plugin_info=(info)
        @plugin_info = PaymentMethodPluginDetailAttributes.new
        @plugin_info.properties = []
        return if info.nil?

        if info['properties'].nil?
          # Convenience method to create properties to add a payment method
          info.each do |key, value|
            property = PluginPropertyAttributes.new
            property.key = key
            property.value = value
            property.is_updatable = false
            @plugin_info.properties << property
          end
        else
          # De-serialization from JSON payload
          info['properties'].each do |property_json|
            property = PluginPropertyAttributes.new
            property.key = property_json['key']
            property.value = property_json['value']
            property.is_updatable = property_json['isUpdatable']
            @plugin_info.properties << property
          end
        end
      end
    end
  end
end
