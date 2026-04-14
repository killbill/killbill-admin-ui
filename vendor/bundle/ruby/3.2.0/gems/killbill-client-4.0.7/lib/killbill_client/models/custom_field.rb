module KillBillClient
  module Model
    class CustomField < CustomFieldAttributes

      include KillBillClient::Model::AuditLogWithHistoryHelper

      KILLBILL_API_CUSTOM_FIELDS_PREFIX = "#{KILLBILL_API_PREFIX}/customFields"

      has_many :audit_logs, KillBillClient::Model::AuditLog

      has_audit_logs_with_history KILLBILL_API_CUSTOM_FIELDS_PREFIX, :custom_field_id

      class << self
        def find_in_batches(offset = 0, limit = 100, audit = 'NONE', options = {})
          get "#{KILLBILL_API_CUSTOM_FIELDS_PREFIX}/#{Resource::KILLBILL_API_PAGINATION_PREFIX}",
              {
                  :offset => offset,
                  :limit  => limit,
                  :audit => audit
              },
              options
        end

        def find_in_batches_by_search_key(search_key, offset = 0, limit = 100, options = {})
          get "#{KILLBILL_API_CUSTOM_FIELDS_PREFIX}/search/#{search_key}",
              {
                  :offset => offset,
                  :limit  => limit
              },
              options
        end

        def find_in_batches_by_search_type_name(object_type, field_name, field_value, offset = 0, limit = 100, options = {})

          query_fields = {
              :objectType => object_type,
              :fieldName => field_name,
              :fieldValue => field_value,
              :offset => offset,
              :limit  => limit
          }
          query_fields[:fieldValue] = field_value if field_value

          get "#{KILLBILL_API_CUSTOM_FIELDS_PREFIX}/search",
              query_fields,
              options
        end

      end
    end
  end
end
